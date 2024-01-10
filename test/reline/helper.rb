$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

ENV['TERM'] = 'xterm' # for some CI environments

require 'reline'
require 'test/unit'
require 'stringio'

begin
  require 'rbconfig'
rescue LoadError
end

begin
  # This should exist and available in load path when this file is mirrored to ruby/ruby and running at there
  if File.exist?(File.expand_path('../../tool/lib/envutil.rb', __dir__))
    require 'envutil'
  end
rescue LoadError
end

module Reline
  class <<self
    def test_mode(ansi: false)
      @original_iogate = IOGate
      remove_const('IOGate')
      const_set('IOGate', ansi ? Reline::ANSI : Reline::GeneralIO)
      if ENV['RELINE_TEST_ENCODING']
        encoding = Encoding.find(ENV['RELINE_TEST_ENCODING'])
      else
        encoding = Encoding::UTF_8
      end
      @original_get_screen_size = IOGate.method(:get_screen_size)
      IOGate.singleton_class.remove_method(:get_screen_size)
      def IOGate.get_screen_size
        [24, 80]
      end
      Reline::GeneralIO.reset(encoding: encoding) unless ansi
      core.config.instance_variable_set(:@test_mode, true)
      core.config.reset
    end

    def test_reset
      IOGate.singleton_class.remove_method(:get_screen_size)
      IOGate.define_singleton_method(:get_screen_size, @original_get_screen_size)
      remove_const('IOGate')
      const_set('IOGate', @original_iogate)
      Reline::GeneralIO.reset
      Reline.instance_variable_set(:@core, nil)
    end

    # Return a executable name to spawn Ruby process. In certain build configuration,
    # "ruby" may not be available.
    def test_rubybin
      # When this test suite is running in ruby/ruby, prefer EnvUtil result over original implementation
      if const_defined?(:EnvUtil)
        return EnvUtil.rubybin
      end

      # The following is a simplified port of EnvUtil.rubybin in ruby/ruby
      if ruby = ENV["RUBY"]
        return ruby
      end
      ruby = "ruby"
      exeext = RbConfig::CONFIG["EXEEXT"]
      rubyexe = (ruby + exeext if exeext and !exeext.empty?)
      if File.exist? ruby and File.executable? ruby and !File.directory? ruby
        return File.expand_path(ruby)
      end
      if rubyexe and File.exist? rubyexe and File.executable? rubyexe
        return File.expand_path(rubyexe)
      end
      if defined?(RbConfig.ruby)
        RbConfig.ruby
      else
        "ruby"
      end
    end
  end
end

def start_pasting
  Reline::GeneralIO.start_pasting
end

def finish_pasting
  Reline::GeneralIO.finish_pasting
end

class Reline::TestCase < Test::Unit::TestCase
  private def convert_str(input, options = {}, normalized = nil)
    return nil if input.nil?
    input.chars.map { |c|
      if Reline::Unicode::EscapedChars.include?(c.ord)
        c
      else
        c.encode(@line_editor.instance_variable_get(:@encoding), Encoding::UTF_8, **options)
      end
    }.join
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    input.unicode_normalize!(:nfc)
    if normalized
      options[:undef] = :replace
      options[:replace] = '?'
    end
    normalized = true
    retry
  end

  def input_key_by_symbol(input)
    @line_editor.input_key(Reline::Key.new(input, input, false))
  end

  def input_keys(input, convert = true)
    input = convert_str(input) if convert
    input.chars.each do |c|
      if c.bytesize == 1
        eighth_bit = 0b10000000
        byte = c.bytes.first
        if byte.allbits?(eighth_bit)
          @line_editor.input_key(Reline::Key.new(byte ^ eighth_bit, byte, true))
        else
          @line_editor.input_key(Reline::Key.new(byte, byte, false))
        end
      else
        c.bytes.each do |b|
          @line_editor.input_key(Reline::Key.new(b, b, false))
        end
      end
    end
  end

  def input_raw_keys(input, convert = true)
    input = convert_str(input) if convert
    input.bytes.each do |b|
      @line_editor.input_key(Reline::Key.new(b, b, false))
    end
  end

  def assert_line(expected)
    expected = convert_str(expected)
    assert_equal(expected, @line_editor.line)
  end

  def assert_byte_pointer_size(expected)
    expected = convert_str(expected)
    byte_pointer = @line_editor.instance_variable_get(:@byte_pointer)
    chunk = @line_editor.line.byteslice(0, byte_pointer)
    assert_equal(
      expected.bytesize, byte_pointer,
      <<~EOM)
        <#{expected.inspect} (#{expected.encoding.inspect})> expected but was
        <#{chunk.inspect} (#{chunk.encoding.inspect})> in <Terminal #{Reline::GeneralIO.encoding.inspect}>
      EOM
  end

  def assert_cursor(expected)
    # This test satisfies nothing because there is no `@cursor` anymore
    # Test editor_cursor_position instead
    cursor_x = @line_editor.instance_eval do
      line_before_cursor = whole_lines[@line_index].byteslice(0, @byte_pointer)
      Reline::Unicode.calculate_width(line_before_cursor)
    end
    assert_equal(expected, cursor_x)
  end

  def assert_cursor_max(expected)
    # This test satisfies nothing because there is no `@cursor_max` anymore
    cursor_max = @line_editor.instance_eval do
      line = whole_lines[@line_index]
      Reline::Unicode.calculate_width(line)
    end
    assert_equal(expected, cursor_max)
  end

  def assert_line_index(expected)
    assert_equal(expected, @line_editor.instance_variable_get(:@line_index))
  end

  def assert_whole_lines(expected)
    assert_equal(expected, @line_editor.whole_lines)
  end

  def assert_key_binding(input, method_symbol, editing_modes = [:emacs, :vi_insert, :vi_command])
    editing_modes.each do |editing_mode|
      @config.editing_mode = editing_mode
      assert_equal(method_symbol, @config.editing_mode.default_key_bindings[input.bytes])
    end
  end

  class PseudoTerminalIO
    def initialize(&block)
      @fiber = Fiber.new(&block)
      @buffer = []
    end

    def start
      @fiber.resume
    end

    def close
      raise 'Already closed' if @closed

      @buffer << nil
      @closed = true
      @fiber.resume
    end

    def read(one)
      raise ArgumentError, 'Only supports read(1)' unless one == 1
      loop do
        Fiber.yield if @buffer.empty? && !@closed
        byte_or_time = @buffer.shift
        case byte_or_time
        when Integer
          return byte_or_time
        when Float
          next
        when nil
          return -1
        end
      end
    end

    def wait_readable(timeout)
      loop do
        Fiber.yield if @buffer.empty? && !@closed
        case @buffer.first
        when Integer
          return self
        when Float
          timeout -= @buffer.shift
          return nil if timeout < 0
        when nil # closed
          return nil
        end
      end
    end

    def current_screen(color: false)
      rendered_lines = Reline.core.line_editor.instance_variable_get(:@rendered_screen).lines
      screen = rendered_lines.map do |items|
        item_ids = []
        items.each_with_index { |(x, w), i| item_ids.fill(i, x, w) }
        (0...item_ids.size).chunk { |i| item_ids[i] || -1 }.map do |id, chunk|
          if id == -1
            ' ' * chunk.size
          else
            x, _w, text = items[id]
            Reline::Unicode.take_range(text, chunk[0] - x, chunk.size)
          end
        end.join
      end
      unless color
        screen.map! do |line|
          line.gsub(/\e\[[0-9;]*m/, '').rstrip
        end
      end
      screen
    end

    def cursor_y
      Reline.core.line_editor.instance_variable_get(:@rendered_screen).cursor_y
    end

    def cursor_x
      # Unlike cursor_y, LineEditor does not store last rendered cursor_x position.
      # So, we need to use calculated value from current state which might not been reflected to terminal screen yet.
      Reline.core.line_editor.wrapped_cursor_position.first
    end

    def write(text)
      raise 'Already closed' if @closed

      text.each_byte { |byte| @buffer << byte }
      @fiber.resume
    end

    def wait(time)
      @buffer << time.to_f
      @fiber.resume
    end
  end

  def assert_readmultiline(prompt: '', add_hist: false, termination_proc:, expected: :unspecified, &block)
    action = -> { Reline.readmultiline(prompt, add_hist, &termination_proc) }
    result = with_pseudo_terminal(action, &block)
    assert_equal(expected, result) unless expected == :unspecified
  end

  def assert_readline(prompt: '', add_hist: false, expected: :unspecified, &block)
    action = -> { Reline.readline(prompt, add_hist) }
    result = with_pseudo_terminal(action, &block)
    assert_equal(expected, result) unless expected == :unspecified
  end

  def with_pseudo_terminal(block)
    original_output = Reline.instance_variable_get(:@output)
    original_input = Reline::GeneralIO.class_variable_get(:@@input)
    original_getc = Reline::GeneralIO.method(:getc)
    Reline::GeneralIO.singleton_class.remove_method(:getc)
    Reline::GeneralIO.define_singleton_method :getc do |timeout_second|
      buf = Reline::GeneralIO.class_variable_get(:@@buf)
      return buf.shift unless buf.empty?
      input = Reline::GeneralIO.class_variable_get(:@@input)
      input.read(1) if input.wait_readable(timeout_second)
    end

    Reline.output = StringIO.new
    result = :not_ended
    io = PseudoTerminalIO.new do
      result = block.call
    end

    Reline::GeneralIO.input = io
    io.start
    yield io
    result
  ensure
    Reline::GeneralIO.input = original_input
    Reline.output = original_output
    Reline::GeneralIO.singleton_class.remove_method(:getc)
    Reline::GeneralIO.define_singleton_method(:getc, original_getc)
  end
end
