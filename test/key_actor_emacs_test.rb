require 'helper'

class Reline::KeyActor::Emacs::Test < Test::Unit::TestCase
  def setup
    @prompt = '> '
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::Emacs, @prompt)
  end

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
        c.bytes.each do |byte|
          @line_editor.input_key(byte)
        end
      end
    end
  end

  def test_ed_insert_one
    input_keys('a')
    assert_equal('a', @line_editor.line)
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_equal('ab', @line_editor.line)
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_equal('か', @line_editor.line)
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_equal('かき', @line_editor.line)
  end

  def test_ed_insert_grapheme_cluster_by_plural_code_points
    input_keys("か\u3099")
    assert_equal("か\u3099", @line_editor.line)
  end

  def test_ed_insert_plural_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_equal("か\u3099き\u3099", @line_editor.line)
  end

  def test_move_next_and_prev
    input_keys("abd\C-b\C-b\C-fc")
    assert_equal('abcd', @line_editor.line)
  end

  def test_move_next_and_prev_for_mbchar
    input_keys("かきけ\C-b\C-b\C-fく")
    assert_equal('かきくけ', @line_editor.line)
  end

  def test_move_next_and_prev_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099け\u3099\C-b\C-b\C-fく\u3099")
    assert_equal("か\u3099き\u3099く\u3099け\u3099", @line_editor.line)
  end

  def test_move_to_beg_end
    input_keys("bcd\C-aa\C-ee")
    assert_equal('abcde', @line_editor.line)
  end

  def test_newline
    input_keys("ab\C-m")
    assert_equal("ab\n", @line_editor.line)
    assert(@line_editor.finished?)
  end

  def test_delete_prev_char
    input_keys("ab\C-h")
    assert_equal('a', @line_editor.line)
  end

  def test_delete_prev_char_for_mbchar
    input_keys("かき\C-h")
    assert_equal('か', @line_editor.line)
  end

  def test_delete_prev_char_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099\C-h")
    assert_equal("か\u3099", @line_editor.line)
  end

  def test_ed_kill_line
    input_keys("\C-k")
    assert_equal('', @line_editor.line)
    input_keys("abc\C-k")
    assert_equal('abc', @line_editor.line)
    input_keys("\C-b\C-k")
    assert_equal('ab', @line_editor.line)
  end

  def test_em_kill_line
    input_keys("\C-u")
    assert_equal('', @line_editor.line)
    input_keys("abc\C-u")
    assert_equal('', @line_editor.line)
    input_keys("abc\C-b\C-u")
    assert_equal('c', @line_editor.line)
    input_keys("\C-u")
    assert_equal('c', @line_editor.line)
  end

  def test_ed_move_to_beg
    input_keys("abd\C-bc\C-a012")
    assert_equal('012abcd', @line_editor.line)
    input_keys("\C-aABC")
    assert_equal('ABC012abcd', @line_editor.line)
    input_keys("\C-f" * 10 + "\C-aa")
    assert_equal('aABC012abcd', @line_editor.line)
  end

  def test_ed_move_to_end
    input_keys("abd\C-bc\C-e012")
    assert_equal('abcd012', @line_editor.line)
    input_keys("\C-eABC")
    assert_equal('abcd012ABC', @line_editor.line)
    input_keys("\C-b" * 10 + "\C-ea")
    assert_equal('abcd012ABCa', @line_editor.line)
  end

  def test_em_delete_or_list
    input_keys("ab\C-a\C-d")
    assert_equal('b', @line_editor.line)
  end

  def test_em_delete_or_list_for_mbchar
    input_keys("かき\C-a\C-d")
    assert_equal('き', @line_editor.line)
  end

  def test_em_delete_or_list_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099\C-a\C-d")
    assert_equal("き\u3099", @line_editor.line)
  end

  def test_ed_clear_screen
    refute(@line_editor.instance_variable_get(:@cleared))
    input_keys("\C-l")
    assert(@line_editor.instance_variable_get(:@cleared))
  end

  def test_em_next_word
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
    input_keys("abc def{bbb}ccc\C-a\M-F")
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-F")
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-F")
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-F")
    assert_equal(15, @line_editor.instance_variable_get(:@cursor))
  end

  def test_em_prev_word
    input_keys("abc def{bbb}ccc")
    assert_equal(15, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-B")
    assert_equal(12, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-B")
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-B")
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    input_keys("\M-B")
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
  end

  def test_em_delete_next_word
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
    input_keys("abc def{bbb}ccc\C-a\M-d")
    assert_equal(' def{bbb}ccc', @line_editor.line)
    input_keys("\M-d")
    assert_equal('{bbb}ccc', @line_editor.line)
    input_keys("\M-d")
    assert_equal('}ccc', @line_editor.line)
    input_keys("\M-d")
    assert_equal('', @line_editor.line)
  end
end
