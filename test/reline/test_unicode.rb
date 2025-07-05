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
    assert_equal 1, Reline::Unicode.calculate_width('√', true)
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
    # IRB uses this method.
    assert_equal [['abc', 'de'], 2], Reline::Unicode.split_by_width('abcde', 3)
  end

  def test_split_line_by_width
    assert_equal ['abc', 'de'], Reline::Unicode.split_line_by_width('abcde', 3)
    assert_equal ['abc', 'def', ''], Reline::Unicode.split_line_by_width('abcdef', 3)
    assert_equal ['ab', 'あd', 'ef'], Reline::Unicode.split_line_by_width('abあdef', 3)
    assert_equal ['ab[zero]c', 'def', ''], Reline::Unicode.split_line_by_width("ab\1[zero]\2cdef", 3)
    assert_equal ["\e[31mabc", "\e[31md\e[42mef", "\e[31m\e[42mg"], Reline::Unicode.split_line_by_width("\e[31mabcd\e[42mefg", 3)
    assert_equal ["ab\e]0;1\ac", "\e]0;1\ad"], Reline::Unicode.split_line_by_width("ab\e]0;1\acd", 3)
  end

  def test_split_line_by_width_csi_reset_sgr_optimization
    assert_equal ["\e[1ma\e[mb\e[2mc", "\e[2md\e[0me\e[3mf", "\e[3mg"], Reline::Unicode.split_line_by_width("\e[1ma\e[mb\e[2mcd\e[0me\e[3mfg", 3)
    assert_equal ["\e[1ma\e[mzero\e[0m\e[2mb", "\e[1m\e[2mc"], Reline::Unicode.split_line_by_width("\e[1ma\1\e[mzero\e[0m\2\e[2mbc", 2)
  end

  def test_take_range
    assert_equal 'cdef', Reline::Unicode.take_range('abcdefghi', 2, 4)
    assert_equal 'あde', Reline::Unicode.take_range('abあdef', 2, 4)
    assert_equal '[zero]cdef', Reline::Unicode.take_range("ab\1[zero]\2cdef", 2, 4)
    assert_equal 'b[zero]cde', Reline::Unicode.take_range("ab\1[zero]\2cdef", 1, 4)
    assert_equal "\e[31mcd\e[42mef", Reline::Unicode.take_range("\e[31mabcd\e[42mefg", 2, 4)
    assert_equal "\e]0;1\acd", Reline::Unicode.take_range("ab\e]0;1\acd", 2, 3)
    assert_equal 'いう', Reline::Unicode.take_range('あいうえお', 2, 4)
  end

  def test_nonprinting_start_end
    # \1 and \2 should be removed
    assert_equal 'ab[zero]cd', Reline::Unicode.take_range("ab\1[zero]\2cdef", 0, 4)
    assert_equal ['ab[zero]cd', 'ef'], Reline::Unicode.split_line_by_width("ab\1[zero]\2cdef", 4)
    # CSI between \1 and \2 does not need to be applied to the sebsequent line
    assert_equal ["\e[31mab\e[32mcd", "\e[31mef"], Reline::Unicode.split_line_by_width("\e[31mab\1\e[32m\2cdef", 4)
  end

  def test_strip_non_printing_start_end
    assert_equal "ab[zero]cd[ze\1ro]ef[zero]", Reline::Unicode.strip_non_printing_start_end("ab\1[zero]\2cd\1[ze\1ro]\2ef\1[zero]")
  end

  def test_calculate_width
    assert_equal 9, Reline::Unicode.calculate_width('abcdefghi')
    assert_equal 9, Reline::Unicode.calculate_width('abcdefghi', true)
    assert_equal 7, Reline::Unicode.calculate_width('abあdef')
    assert_equal 7, Reline::Unicode.calculate_width('abあdef', true)
    assert_equal 16, Reline::Unicode.calculate_width("ab\1[zero]\2cdef")
    assert_equal 6, Reline::Unicode.calculate_width("ab\1[zero]\2cdef", true)
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
    assert_equal ["\e[31mc[ABC]d\e[0mef", 2, 4], Reline::Unicode.take_mbchar_range("\e[31mabc\1[ABC]\2d\e[0mefghi", 2, 4)
    assert_equal ["\e[41m \e[42mい\e[43m ", 1, 4], Reline::Unicode.take_mbchar_range("\e[41mあ\e[42mい\e[43mう", 1, 4, padding: true)
  end

  def test_three_width_characters_take_mbchar_range
    halfwidth_dakuten = 0xFF9E.chr('utf-8')
    a = 'あ' + halfwidth_dakuten
    b = 'い' + halfwidth_dakuten
    c = 'う' + halfwidth_dakuten
    line = 'x' + a + b + c + 'x'
    assert_equal ['  ' + b + ' ', 2, 6], Reline::Unicode.take_mbchar_range(line, 2, 6, padding: true)
    assert_equal [' ' + b + '  ', 3, 6], Reline::Unicode.take_mbchar_range(line, 3, 6, padding: true)
    assert_equal [b + c, 4, 6], Reline::Unicode.take_mbchar_range(line, 4, 6, padding: true)
    assert_equal [a + b, 1, 6], Reline::Unicode.take_mbchar_range(line, 2, 6, cover_begin: true)
    assert_equal [a + b, 1, 6], Reline::Unicode.take_mbchar_range(line, 3, 6, cover_begin: true)
    assert_equal [b + c, 4, 6], Reline::Unicode.take_mbchar_range(line, 2, 6, cover_end: true)
    assert_equal [b + c, 4, 6], Reline::Unicode.take_mbchar_range(line, 3, 6, cover_end: true)
  end

  def test_common_prefix
    assert_equal('', Reline::Unicode.common_prefix([]))
    assert_equal('abc', Reline::Unicode.common_prefix(['abc']))
    assert_equal('12', Reline::Unicode.common_prefix(['123', '123️⃣']))
    assert_equal('', Reline::Unicode.common_prefix(['abc', 'xyz']))
    assert_equal('ab', Reline::Unicode.common_prefix(['abcd', 'abc', 'abx', 'abcd']))
    assert_equal('A', Reline::Unicode.common_prefix(['AbcD', 'ABC', 'AbX', 'AbCD']))
    assert_equal('Ab', Reline::Unicode.common_prefix(['AbcD', 'ABC', 'AbX', 'AbCD'], ignore_case: true))
  end

  def test_encoding_conversion
    texts = [
      String.new("invalid\xFFutf8", encoding: 'utf-8'),
      String.new("invalid\xFFsjis", encoding: 'sjis'),
      "utf8#{33111.chr('sjis')}convertible",
      "utf8#{33222.chr('sjis')}inconvertible",
      "sjis->utf8->sjis#{60777.chr('sjis')}irreversible"
    ]
    utf8_texts = [
      'invalid�utf8',
      'invalid�sjis',
      'utf8仝convertible',
      'utf8�inconvertible',
      'sjis->utf8->sjis劦irreversible'
    ]
    sjis_texts = [
      'invalid?utf8',
      'invalid?sjis',
      "utf8#{33111.chr('sjis')}convertible",
      'utf8?inconvertible',
      "sjis->utf8->sjis#{60777.chr('sjis')}irreversible"
    ]
    assert_equal(utf8_texts, texts.map { |s| Reline::Unicode.safe_encode(s, 'utf-8') })
    assert_equal(utf8_texts, texts.map { |s| Reline::Unicode.safe_encode(s, Encoding::UTF_8) })
    assert_equal(sjis_texts, texts.map { |s| Reline::Unicode.safe_encode(s, 'sjis') })
    assert_equal(sjis_texts, texts.map { |s| Reline::Unicode.safe_encode(s, Encoding::Windows_31J) })
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
    assert_equal(2, Reline::Unicode.vi_forward_word('abc   def', 1, true))
    assert_equal(5, Reline::Unicode.vi_forward_word('abc   def', 1, false))
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

  def test_halfwidth_dakuten_handakuten_combinations
    assert_equal 1, Reline::Unicode.get_mbchar_width("\uFF9E")
    assert_equal 1, Reline::Unicode.get_mbchar_width("\uFF9F")
    assert_equal 2, Reline::Unicode.get_mbchar_width("ｶﾞ")
    assert_equal 2, Reline::Unicode.get_mbchar_width("ﾊﾟ")
    assert_equal 2, Reline::Unicode.get_mbchar_width("ｻﾞ")
    assert_equal 2, Reline::Unicode.get_mbchar_width("aﾞ")
    assert_equal 2, Reline::Unicode.get_mbchar_width("1ﾟ")
    assert_equal 3, Reline::Unicode.get_mbchar_width("あﾞ")
    assert_equal 3, Reline::Unicode.get_mbchar_width("紅ﾞ")
  end
end
