require 'io/console'
require 'reline/version'
require 'reline/config'
require 'reline/key_actor'
require 'reline/key_stroke'
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

  @@ambiguous_width = nil
  @@config = nil

  @basic_quote_characters = '"\''
  @basic_word_break_characters = " \t\n`><=;|&{("
  @completer_quote_characters
  @completer_word_break_characters = @basic_word_break_characters.dup
  @completion_append_character
  def self.completion_append_character=(val)
    if val.nil?
      @completion_append_character = nil
    elsif val.size == 1
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

  if IS_WINDOWS
    require 'reline/windows'
  else
    require 'reline/ansi'
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

  def self.readmultiline(prompt = '', add_hist = false, &confirm_multiline_termination)
    if block_given?
      inner_readline(prompt, add_hist, true, &confirm_multiline_termination)
    else
      inner_readline(prompt, add_hist, true)
    end

    @line_editor.whole_buffer
  end

  def self.readline(prompt = '', add_hist = false)
    inner_readline(prompt, add_hist, false)

    @line_editor.line
  end

  def self.inner_readline(prompt = '', add_hist = false, multiline, &confirm_multiline_termination)
    if @@config.nil?
      @@config = Reline::Config.new
      @@config.read
    end
    otio = prep

    may_req_ambiguous_char_width
    @line_editor = Reline::LineEditor.new(@@config, prompt)
    if multiline
      @line_editor.multiline_on
      if block_given?
        @line_editor.confirm_multiline_termination_proc = confirm_multiline_termination
      end
    end
    @line_editor.completion_proc = @completion_proc
    @line_editor.retrieve_completion_block = method(:retrieve_completion_block)
    @line_editor.rerender

    config = {
      key_mapping: {
        [27, 91, 65] => :ed_prev_history,    # ↑
        [27, 91, 66] => :ed_next_history,    # ↓
        [27, 91, 67] => :ed_next_char,       # →
        [27, 91, 68] => :ed_prev_char        # ←
      }
    }

    key_stroke = Reline::KeyStroke.new(config)
    begin
      while c = getc
        key_stroke.input_to!(c)&.then { |inputs|
          inputs.each { |c|
            @line_editor.input_key(c)
            @line_editor.rerender
          }
        }
        break if @line_editor.finished?
      end
      move_cursor_column(0)
      if add_hist and @line_editor.line and @line_editor.line.chomp.size > 0
        Reline::HISTORY << @line_editor.line.chomp
      end
    rescue StandardError => e
      deprep(otio)
      raise e
    end

    deprep(otio)
  end

  def self.may_req_ambiguous_char_width
    return if @@ambiguous_width
    move_cursor_column(0)
    print "\u{25bd}"
    @@ambiguous_width = cursor_pos.x
    move_cursor_column(0)
    erase_after_cursor
  end

  def self.ambiguous_width
    @@ambiguous_width
  end
end
