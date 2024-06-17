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

  def test_csi_regexp
    csi_sequences = ["\e[m", "\e[1m", "\e[12;34m", "\e[12;34H"]
    assert_equal(csi_sequences, "text#{csi_sequences.join('text')}text".scan(Reline::Unicode::CSI_REGEXP))
  end

  def test_osc_regexp
    osc_sequences = ["\e]1\a", "\e]0;OSC\a", "\e]1\e\\", "\e]0;OSC\e\\"]
    separator = "text\atext"
    assert_equal(osc_sequences, "#{separator}#{osc_sequences.join(separator)}#{separator}".scan(Reline::Unicode::OSC_REGEXP))
  end

  def test_split_by_width
    assert_equal [['abc', 'de'], 2], Reline::Unicode.split_by_width('abcde', 3)
    assert_equal [['abc', 'def', ''], 3], Reline::Unicode.split_by_width('abcdef', 3)
    assert_equal [['ab', 'あd', 'ef'], 3], Reline::Unicode.split_by_width('abあdef', 3)
    assert_equal [["ab\1zero\2c", 'def', ''], 3], Reline::Unicode.split_by_width("ab\1zero\2cdef", 3)
    assert_equal [["\e[31mabc", "\e[31md\e[42mef", "\e[31m\e[42mg"], 3], Reline::Unicode.split_by_width("\e[31mabcd\e[42mefg", 3)
    assert_equal [["ab\e]0;1\ac", "\e]0;1\ad"], 2], Reline::Unicode.split_by_width("ab\e]0;1\acd", 3)
  end

  def test_split_by_width_csi_reset_sgr_optimization
    assert_equal [["\e[1ma\e[mb\e[2mc", "\e[2md\e[0me\e[3mf", "\e[3mg"], 3], Reline::Unicode.split_by_width("\e[1ma\e[mb\e[2mcd\e[0me\e[3mfg", 3)
    assert_equal [["\e[1ma\1\e[mzero\e[0m\2\e[2mb", "\e[1m\e[2mc"], 2], Reline::Unicode.split_by_width("\e[1ma\1\e[mzero\e[0m\2\e[2mbc", 2)
  end

  def test_take_range
    assert_equal 'cdef', Reline::Unicode.take_range('abcdefghi', 2, 4)
    assert_equal 'あde', Reline::Unicode.take_range('abあdef', 2, 4)
    assert_equal "\1zero\2cdef", Reline::Unicode.take_range("ab\1zero\2cdef", 2, 4)
    assert_equal "b\1zero\2cde", Reline::Unicode.take_range("ab\1zero\2cdef", 1, 4)
    assert_equal "\e[31mcd\e[42mef", Reline::Unicode.take_range("\e[31mabcd\e[42mefg", 2, 4)
    assert_equal "\e]0;1\acd", Reline::Unicode.take_range("ab\e]0;1\acd", 2, 3)
    assert_equal 'いう', Reline::Unicode.take_range('あいうえお', 2, 4)
  end

  def test_calculate_width
    assert_equal 9, Reline::Unicode.calculate_width('abcdefghi')
    assert_equal 9, Reline::Unicode.calculate_width('abcdefghi', true)
    assert_equal 7, Reline::Unicode.calculate_width('abあdef')
    assert_equal 7, Reline::Unicode.calculate_width('abあdef', true)
    assert_equal 14, Reline::Unicode.calculate_width("ab\1zero\2cdef")
    assert_equal 6, Reline::Unicode.calculate_width("ab\1zero\2cdef", true)
    assert_equal 19, Reline::Unicode.calculate_width("\e[31mabcd\e[42mefg")
    assert_equal 7, Reline::Unicode.calculate_width("\e[31mabcd\e[42mefg", true)
    assert_equal 12, Reline::Unicode.calculate_width("ab\e]0;1\acd")
    assert_equal 4, Reline::Unicode.calculate_width("ab\e]0;1\acd", true)
    assert_equal 10, Reline::Unicode.calculate_width('あいうえお')
    assert_equal 10, Reline::Unicode.calculate_width('あいうえお', true)
  end

  def test_take_mbchar_range
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_mbchar_range('abcdefghi', 2, 4)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_mbchar_range('abcdefghi', 2, 4, padding: true)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_mbchar_range('abcdefghi', 2, 4, cover_begin: true)
    assert_equal ['cdef', 2, 4], Reline::Unicode.take_mbchar_range('abcdefghi', 2, 4, cover_end: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_mbchar_range('あいうえお', 2, 4)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_mbchar_range('あいうえお', 2, 4, padding: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_mbchar_range('あいうえお', 2, 4, cover_begin: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_mbchar_range('あいうえお', 2, 4, cover_end: true)
    assert_equal ['う', 4, 2], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4)
    assert_equal [' う ', 3, 4], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4, padding: true)
    assert_equal ['いう', 2, 4], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4, cover_begin: true)
    assert_equal ['うえ', 4, 4], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4, cover_end: true)
    assert_equal ['いう ', 2, 5], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4, cover_begin: true, padding: true)
    assert_equal [' うえ', 3, 5], Reline::Unicode.take_mbchar_range('あいうえお', 3, 4, cover_end: true, padding: true)
    assert_equal [' うえお   ', 3, 10], Reline::Unicode.take_mbchar_range('あいうえお', 3, 10, padding: true)
    assert_equal [" \e[41mうえお\e[0m   ", 3, 10], Reline::Unicode.take_mbchar_range("あい\e[41mうえお", 3, 10, padding: true)
    assert_equal ["\e[41m \e[42mい\e[43m ", 1, 4], Reline::Unicode.take_mbchar_range("\e[41mあ\e[42mい\e[43mう", 1, 4, padding: true)
    assert_equal ["\e[31mc\1ABC\2d\e[0mef", 2, 4], Reline::Unicode.take_mbchar_range("\e[31mabc\1ABC\2d\e[0mefghi", 2, 4)
    assert_equal ["\e[41m \e[42mい\e[43m ", 1, 4], Reline::Unicode.take_mbchar_range("\e[41mあ\e[42mい\e[43mう", 1, 4, padding: true)
  end

  def test_em_forward_word
    assert_equal(12, Reline::Unicode.em_forward_word('abc---fooあbar-baz', 3))
    assert_equal(11, Reline::Unicode.em_forward_word('abc---fooあbar-baz'.encode('sjis'), 3))
    assert_equal(3, Reline::Unicode.em_forward_word('abcfoo', 3))
    assert_equal(3, Reline::Unicode.em_forward_word('abc---', 3))
    assert_equal(0, Reline::Unicode.em_forward_word('abc', 3))
  end

  def test_em_forward_word_with_capitalization
    assert_equal([12, '---Fooあbar'], Reline::Unicode.em_forward_word_with_capitalization('abc---foOあBar-baz', 3))
    assert_equal([11, '---Fooあbar'.encode('sjis')], Reline::Unicode.em_forward_word_with_capitalization('abc---foOあBar-baz'.encode('sjis'), 3))
    assert_equal([3, 'Foo'], Reline::Unicode.em_forward_word_with_capitalization('abcfOo', 3))
    assert_equal([3, '---'], Reline::Unicode.em_forward_word_with_capitalization('abc---', 3))
    assert_equal([0, ''], Reline::Unicode.em_forward_word_with_capitalization('abc', 3))
    assert_equal([6, 'Ii̇i̇'], Reline::Unicode.em_forward_word_with_capitalization('ıİİ', 0))
  end

  def test_em_backward_word
    assert_equal(12, Reline::Unicode.em_backward_word('abc foo-barあbaz--- xyz', 20))
    assert_equal(11, Reline::Unicode.em_backward_word('abc foo-barあbaz--- xyz'.encode('sjis'), 19))
    assert_equal(2, Reline::Unicode.em_backward_word('  ', 2))
    assert_equal(2, Reline::Unicode.em_backward_word('ab', 2))
    assert_equal(0, Reline::Unicode.em_backward_word('ab', 0))
  end

  def test_em_big_backward_word
    assert_equal(16, Reline::Unicode.em_big_backward_word('abc foo-barあbaz--- xyz', 20))
    assert_equal(15, Reline::Unicode.em_big_backward_word('abc foo-barあbaz--- xyz'.encode('sjis'), 19))
    assert_equal(2, Reline::Unicode.em_big_backward_word('  ', 2))
    assert_equal(2, Reline::Unicode.em_big_backward_word('ab', 2))
    assert_equal(0, Reline::Unicode.em_big_backward_word('ab', 0))
  end

  def test_ed_transpose_words
    # any value that does not trigger transpose
    assert_equal([0, 0, 0, 2], Reline::Unicode.ed_transpose_words('aa bb cc  ', 1))

    assert_equal([0, 2, 3, 5], Reline::Unicode.ed_transpose_words('aa bb cc  ', 2))
    assert_equal([0, 2, 3, 5], Reline::Unicode.ed_transpose_words('aa bb cc  ', 4))
    assert_equal([3, 5, 6, 8], Reline::Unicode.ed_transpose_words('aa bb cc  ', 5))
    assert_equal([3, 5, 6, 8], Reline::Unicode.ed_transpose_words('aa bb cc  ', 7))
    assert_equal([3, 5, 6, 10], Reline::Unicode.ed_transpose_words('aa bb cc  ', 8))
    assert_equal([3, 5, 6, 10], Reline::Unicode.ed_transpose_words('aa bb cc  ', 9))
    ['sjis', 'utf-8'].each do |encoding|
      texts = ['fooあ', 'barあbaz', 'aaa  -', '- -', '-  bbb']
      word1, word2, left, middle, right = texts.map { |text| text.encode(encoding) }
      expected = [left.bytesize, (left + word1).bytesize, (left + word1 + middle).bytesize, (left + word1 + middle + word2).bytesize]
      assert_equal(expected, Reline::Unicode.ed_transpose_words(left + word1 + middle + word2 + right, left.bytesize + word1.bytesize))
      assert_equal(expected, Reline::Unicode.ed_transpose_words(left + word1 + middle + word2 + right, left.bytesize + word1.bytesize + middle.bytesize))
      assert_equal(expected, Reline::Unicode.ed_transpose_words(left + word1 + middle + word2 + right, left.bytesize + word1.bytesize + middle.bytesize + word2.bytesize - 1))
    end
  end

  def test_vi_big_forward_word
    assert_equal(18, Reline::Unicode.vi_big_forward_word('abc---fooあbar-baz  xyz', 3))
    assert_equal(8, Reline::Unicode.vi_big_forward_word('abcfooあ  --', 3))
    assert_equal(7, Reline::Unicode.vi_big_forward_word('abcfooあ  --'.encode('sjis'), 3))
    assert_equal(6, Reline::Unicode.vi_big_forward_word('abcfooあ', 3))
    assert_equal(3, Reline::Unicode.vi_big_forward_word('abc-  ', 3))
    assert_equal(0, Reline::Unicode.vi_big_forward_word('abc', 3))
  end

  def test_vi_big_forward_end_word
    assert_equal(4, Reline::Unicode.vi_big_forward_end_word('a  bb c', 0))
    assert_equal(4, Reline::Unicode.vi_big_forward_end_word('-  bb c', 0))
    assert_equal(1, Reline::Unicode.vi_big_forward_end_word('-a b', 0))
    assert_equal(1, Reline::Unicode.vi_big_forward_end_word('a- b', 0))
    assert_equal(1, Reline::Unicode.vi_big_forward_end_word('aa b', 0))
    assert_equal(3, Reline::Unicode.vi_big_forward_end_word('  aa b', 0))
    assert_equal(15, Reline::Unicode.vi_big_forward_end_word('abc---fooあbar-baz  xyz', 3))
    assert_equal(14, Reline::Unicode.vi_big_forward_end_word('abc---fooあbar-baz  xyz'.encode('sjis'), 3))
    assert_equal(3, Reline::Unicode.vi_big_forward_end_word('abcfooあ  --', 3))
    assert_equal(3, Reline::Unicode.vi_big_forward_end_word('abcfooあ', 3))
    assert_equal(2, Reline::Unicode.vi_big_forward_end_word('abc-  ', 3))
    assert_equal(0, Reline::Unicode.vi_big_forward_end_word('abc', 3))
  end

  def test_vi_big_backward_word
    assert_equal(16, Reline::Unicode.vi_big_backward_word('abc foo-barあbaz--- xyz', 20))
    assert_equal(15, Reline::Unicode.vi_big_backward_word('abc foo-barあbaz--- xyz'.encode('sjis'), 19))
    assert_equal(2, Reline::Unicode.vi_big_backward_word('  ', 2))
    assert_equal(2, Reline::Unicode.vi_big_backward_word('ab', 2))
    assert_equal(0, Reline::Unicode.vi_big_backward_word('ab', 0))
  end

  def test_vi_forward_word
    assert_equal(3, Reline::Unicode.vi_forward_word('abc---fooあbar-baz', 3))
    assert_equal(9, Reline::Unicode.vi_forward_word('abc---fooあbar-baz', 6))
    assert_equal(8, Reline::Unicode.vi_forward_word('abc---fooあbar-baz'.encode('sjis'), 6))
    assert_equal(6, Reline::Unicode.vi_forward_word('abcfooあ', 3))
    assert_equal(3, Reline::Unicode.vi_forward_word('abc---', 3))
    assert_equal(0, Reline::Unicode.vi_forward_word('abc', 3))
  end

  def test_vi_forward_end_word
    assert_equal(2, Reline::Unicode.vi_forward_end_word('abc---fooあbar-baz', 3))
    assert_equal(8, Reline::Unicode.vi_forward_end_word('abc---fooあbar-baz', 6))
    assert_equal(7, Reline::Unicode.vi_forward_end_word('abc---fooあbar-baz'.encode('sjis'), 6))
    assert_equal(3, Reline::Unicode.vi_forward_end_word('abcfooあ', 3))
    assert_equal(2, Reline::Unicode.vi_forward_end_word('abc---', 3))
    assert_equal(0, Reline::Unicode.vi_forward_end_word('abc', 3))
  end

  def test_vi_backward_word
    assert_equal(3, Reline::Unicode.vi_backward_word('abc foo-barあbaz--- xyz', 20))
    assert_equal(9, Reline::Unicode.vi_backward_word('abc foo-barあbaz--- xyz', 17))
    assert_equal(8, Reline::Unicode.vi_backward_word('abc foo-barあbaz--- xyz'.encode('sjis'), 16))
    assert_equal(2, Reline::Unicode.vi_backward_word('  ', 2))
    assert_equal(2, Reline::Unicode.vi_backward_word('ab', 2))
    assert_equal(0, Reline::Unicode.vi_backward_word('ab', 0))
  end

  def test_vi_first_print
    assert_equal(3, Reline::Unicode.vi_first_print('   abcdefg'))
    assert_equal(3, Reline::Unicode.vi_first_print('   '))
    assert_equal(0, Reline::Unicode.vi_first_print('abc'))
    assert_equal(0, Reline::Unicode.vi_first_print('あ'))
    assert_equal(0, Reline::Unicode.vi_first_print('あ'.encode('sjis')))
    assert_equal(0, Reline::Unicode.vi_first_print(''))
  end

  def test_character_type
    assert(Reline::Unicode.word_character?('a'))
    assert(Reline::Unicode.word_character?('あ'))
    assert(Reline::Unicode.word_character?('あ'.encode('sjis')))
    refute(Reline::Unicode.word_character?(33345.chr('sjis')))
    refute(Reline::Unicode.word_character?('-'))
    refute(Reline::Unicode.word_character?(nil))

    assert(Reline::Unicode.space_character?(' '))
    refute(Reline::Unicode.space_character?('あ'))
    refute(Reline::Unicode.space_character?('あ'.encode('sjis')))
    refute(Reline::Unicode.space_character?(33345.chr('sjis')))
    refute(Reline::Unicode.space_character?('-'))
    refute(Reline::Unicode.space_character?(nil))
  end
end
