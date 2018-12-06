$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'reline'
require 'test-unit'

RELINE_TEST_ENCODING = Encoding.find(ENV['RELINE_TEST_ENCODING']) if ENV['RELINE_TEST_ENCODING']

class Reline::TestCase < Test::Unit::TestCase
  def input_keys(input, convert = true)
    input.encode!(@line_editor.instance_variable_get(:@encoding)) if convert
    input.chars.each do |c|
      if c.bytesize == 1
        eighth_bit = 0b10000000
        byte = c.bytes.first
        if byte.allbits?(eighth_bit)
          @line_editor.input_key("\e".ord)
          byte ^= eighth_bit
        end
        @line_editor.input_key(byte)
      else
        c.bytes.each do |b|
          @line_editor.input_key(b)
        end
      end
    end
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    input.unicode_normalize!(:nfc)
    retry
  end

  def assert_line(expected)
    expected.encode!(@line_editor.instance_variable_get(:@encoding))
    assert_equal(expected, @line_editor.line)
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    expected.unicode_normalize!(:nfc)
    retry
  end

  def assert_byte_pointer_size(expected)
    expected.encode!(@line_editor.instance_variable_get(:@encoding))
    assert_equal(expected.bytesize, @line_editor.instance_variable_get(:@byte_pointer))
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    expected.unicode_normalize!(:nfc)
    retry
  end

  def assert_cursor(expected)
    assert_equal(expected, @line_editor.instance_variable_get(:@cursor))
  end

  def assert_cursor_max(expected)
    assert_equal(expected, @line_editor.instance_variable_get(:@cursor_max))
  end
end
