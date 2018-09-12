require 'io/console'
require 'reline/version'
require 'reline/key_actor'
require 'reline/line_editor'

module Reline
  FILENAME_COMPLETION_PROC = nil
  USERNAME_COMPLETION_PROC = nil
  HISTORY = Array.new

  if RUBY_PLATFORM =~ /mswin|mingw/
    require 'Win32API'
    IS_WINDOWS = true
  else
    IS_WINDOWS = false
  end

  CursorPos = Struct.new(:x, :y)

  class << self
    attr_accessor :basic_quote_characters
    attr_accessor :basic_word_break_characters
    attr_accessor :completer_quote_characters
    attr_accessor :completer_word_break_characters
    attr_reader :completion_append_character
    attr_accessor :completion_case_fold
    attr_accessor :completion_proc
    attr_accessor :filename_quote_characters
    attr_writer :input
    attr_writer :output
  end

  @basic_quote_characters = '"\''
  @basic_word_break_characters = " \t\n`><=;|&{("
  @completer_quote_characters
  @completer_word_break_characters = @basic_word_break_characters.dup
  @completion_append_character
  def self.completion_append_character=(val)
    if val.size == 1
      @completion_append_character = val
    elsif val.size > 1
      @completion_append_character = val[0]
    else
      @completion_append_character = val
    end
  end
  @completion_case_fold
  @completion_proc
  @filename_quote_characters

  def self.vi_editing_mode
    nil
  end

  def self.emacs_editing_mode
    nil
  end

  if IS_WINDOWS
    VK_LMENU = 0xA4
    STD_OUTPUT_HANDLE = -11
    @@getch = Win32API.new("msvcrt", "_getch", [], 'I')
    @@kbhit = Win32API.new("msvcrt", "_kbhit", [], 'I')
    @@GetKeyState = Win32API.new("user32","GetKeyState",['L'],'L')
    @@GetConsoleScreenBufferInfo = Win32API.new("kernel32", "GetConsoleScreenBufferInfo", ['L', 'P'], 'L')
    @@GetStdHandle = Win32API.new("kernel32", "GetStdHandle", ['L'], 'L')
    @@hConsoleHandle = @@GetStdHandle.Call(STD_OUTPUT_HANDLE)
    @@buf = []

    def self.getc
      unless @@buf.empty?
        return @@buf.shift
      end
      while @@kbhit.Call == 0
        sleep(0.001)
      end
      c = @@getch.Call
      alt = (@@GetKeyState.call(VK_LMENU) & 0x80) != 0
      if c == 0 or c == 0xE0
        while @@kbhit.Call == 0
          sleep(0.001)
        end
        r = c.chr + @@getch.Call.chr
      else
        r = c.chr
      end
      if alt
        @@buf << r.ord
        "\e".ord
      else
        r.ord
      end
    end

    def self.get_screen_size
      csbi = 0.chr * 24
      @@GetConsoleScreenBufferInfo.Call(@@hConsoleHandle, csbi)
      csbi[0, 4].unpack('SS')
    end

    def self.set_screen_size(rows, columns)
      raise NotImplementedError
    end

    def self.prep
      # do nothing
      nil
    end

    def self.deprep(otio)
      # do nothing
    end
  else
    @@buf = []

    def self.getc
      return @@buf.shift unless @@buf.empty?
      return nil if @line_editor.finished?
      while select([$stdin], [], [], 0.00001).nil?
      end
      c = nil
      until select([$stdin], [], [], 0.00001).nil?
        @@buf << $stdin.read(1).ord
      end
      c = @@buf.shift
      return c
    end

    def self.get_screen_size
      $stdin.winsize
    end

    def self.set_screen_size(rows, columns)
      $stdin.winsize = [rows, columns]
      self
    end

    def self.cursor_pos
      res = ''
      $stdin.raw do |stdin|
        $stdout << "\e[6n"
        $stdout.flush
        while (c = stdin.getc) != 'R'
          res << c if c
        end
      end
      m = res.match /(?<row>\d+);(?<column>\d+)/
      CursorPos.new(m[:column].to_i, m[:row].to_i)
    end

    def self.prep
      int_handle = Signal.trap('INT', 'IGNORE')
      otio = `stty -g`.chomp
      setting = ' -echo -icrnl cbreak'
      if (`stty -a`.scan(/-parenb\b/).first == '-parenb')
        setting << ' pass8'
      end
      setting << ' -ixoff'
      `stty #{setting}`
      Signal.trap('INT', int_handle)
      otio
    end

    def self.deprep(otio)
      int_handle = Signal.trap('INT', 'IGNORE')
      `stty #{otio}`
      Signal.trap('INT', int_handle)
    end
  end

  def self.retrieve_completion_block(line, byte_pointer)
    break_regexp = /[#{Regexp.escape(@basic_word_break_characters)}]/
    before_pointer = line.byteslice(0, byte_pointer)
    break_point = before_pointer.rindex(break_regexp)
    if break_point
      preposing = before_pointer[0..(break_point)]
      block = before_pointer[(break_point + 1)..-1]
    else
      preposing = ''
      block = before_pointer
    end
    postposing = line.byteslice(byte_pointer, line.bytesize)
    [preposing, block, postposing]
  end

  def self.readline(prompt = '', add_hist = false)
    otio = prep

    @line_editor = Reline::LineEditor.new(Reline::KeyActor::Emacs, prompt)
    @line_editor.completion_proc = @completion_proc
    @line_editor.retrieve_completion_block = method(:retrieve_completion_block)
    @line_editor.rerender
    begin
      while c = getc
        @line_editor.input_key(c)
        @line_editor.rerender
        break if @line_editor.finished?
      end
      print "\e[1G"
      if add_hist and @line_editor.line and @line_editor.line.chomp.size > 0
        Reline::HISTORY << @line_editor.line.chomp
      end
    rescue StandardError => e
      deprep(otio)
      raise e
    end

    deprep(otio)

    @line_editor.line
  end
end
