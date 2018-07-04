require 'io/console'
require 'reline/version'
require 'reline/key_actor'
require 'reline/line_editor'

module Reline
  FILENAME_COMPLETION_PROC = nil
  USERNAME_COMPLETION_PROC = nil
  HISTORY = Array.new

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

  def self.get_screen_size
    $stdin.winsize
  end

  def self.set_screen_size(rows, columns)
    $stdin.winsize = [rows, columns]
    self
  end

  def self.getc
    c = nil
    until c
      return nil if @line_editor.finished?
      result = select([$stdin], [], [], 0.1)
      next if result.nil?
      c = $stdin.read(1)
    end
    c.ord
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
