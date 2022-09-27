require_relative 'helper'
require "reline/unicode"

class Reline::Unicode::Test < Reline::TestCase
  def setup
    Reline.send(:test_mode)
  end

  def teardown
    Reline.test_reset
  end

  def test_get_mbchar_width
    assert_equal Reline.ambiguous_width, Reline::Unicode.get_mbchar_width('é')
  end

  def test_ambiguous_width
    assert_equal 2, Reline::Unicode.calculate_width('√', true)
  end

  def test_take_range
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_range('abcdefghi', 2, 4)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_range('abcdefghi', 2, 4, padding: true)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_range('abcdefghi', 2, 4, cover_begin: true)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_range('abcdefghi', 2, 4, cover_end: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_range('あいうえお', 2, 4)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_range('あいうえお', 2, 4, padding: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_range('あいうえお', 2, 4, cover_begin: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_range('あいうえお', 2, 4, cover_end: true)
    assert_equal ['う', 4, 2], Reline::Unicode.take_range('あいうえお', 3, 4)
    assert_equal [' う ', 3, 4], Reline::Unicode.take_range('あいうえお', 3, 4, padding: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_range('あいうえお', 3, 4, cover_begin: true)
    assert_equal ['うえ', 4, 4], Reline::Unicode.take_range('あいうえお', 3, 4, cover_end: true)
    assert_equal ['いう ', 2, 5], Reline::Unicode.take_range('あいうえお', 3, 4, cover_begin: true, padding: true)
    assert_equal [' うえ', 3, 5], Reline::Unicode.take_range('あいうえお', 3, 4, cover_end: true, padding: true)
    assert_equal [' うえお   ', 3, 10], Reline::Unicode.take_range('あいうえお', 3, 10, padding: true)
    assert_equal ["\e[31mc\1ABC\2d\e[0mef", 2, 4], Reline::Unicode.take_range("\e[31mabc\1ABC\2d\e[0mefghi", 2, 4)
  end
end
