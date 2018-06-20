$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'reline'
require 'test-unit'

class Reline::TestCase < Test::Unit::TestCase
  def input_keys(input)
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
  end
end
