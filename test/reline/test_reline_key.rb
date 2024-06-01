require_relative 'helper'
require "reline"

class Reline::TestKey < Reline::TestCase
  def test_match_symbol
    bytes = "\e[dummy_bytes".bytes
    assert(Reline::Key.new('a', :key2, bytes).match?(:key2))
    assert(Reline::Key.new(12, :key1, bytes).match?(:key1))
    assert(Reline::Key.new(12, :key3, bytes).match?(:key3))

    refute(Reline::Key.new('a', :key2, bytes).match?(:key1))
    refute(Reline::Key.new(12, :key1, bytes).match?(:key2))
    refute(Reline::Key.new(nil, :key3, bytes).match?(:key4))
  end

  def test_match_symbol_wrongly_used_in_irb
    refute(Reline::Key.new(nil, 0xE4, true).match?(:foo))
  end
end
