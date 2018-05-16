require 'helper'

class Reline::KeyActor::Emacs::Test < Test::Unit::TestCase
  def setup
    @prompt = '> '
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::Emacs, @prompt)
  end

  def input_keys(input)
    input.bytes.each do |byte|
      @line_editor.input_key(byte)
    end
  end

  def test_ed_insert_one
    input_keys('a')
    assert_equal(@line_editor.line, 'a')
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_equal(@line_editor.line, 'ab')
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_equal(@line_editor.line, 'か')
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_equal(@line_editor.line, 'かき')
  end

  def test_ed_insert_grapheme_cluster_by_plural_code_points
    input_keys("か\u3099")
    assert_equal(@line_editor.line, "か\u3099")
  end

  def test_ed_insert_plural_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_equal(@line_editor.line, "か\u3099き\u3099")
  end

  def test_move_next_and_prev
    input_keys("abd\C-b\C-b\C-fc")
    assert_equal(@line_editor.line, 'abcd')
  end

  def test_move_next_and_prev_for_mbchar
    input_keys("かきけ\C-b\C-b\C-fく")
    assert_equal(@line_editor.line, 'かきくけ')
  end

  def test_move_next_and_prev_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099け\u3099\C-b\C-b\C-fく\u3099")
    assert_equal(@line_editor.line, "か\u3099き\u3099く\u3099け\u3099")
  end

  def test_move_to_beg_end
    input_keys("bcd\C-aa\C-ee")
    assert_equal(@line_editor.line, 'abcde')
  end

  def test_newline
    input_keys("ab\C-m")
    assert_equal(@line_editor.line, "ab\n")
    assert(@line_editor.finished?)
  end

  def test_delete_prev_char
    input_keys("ab\C-h")
    assert_equal(@line_editor.line, 'a')
  end

  def test_delete_prev_char_for_mbchar
    input_keys("かき\C-h")
    assert_equal(@line_editor.line, 'か')
  end

  def test_delete_prev_char_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099\C-h")
    assert_equal(@line_editor.line, "か\u3099")
  end

  def test_ed_kill_line
    input_keys("\C-k")
    assert_equal(@line_editor.line, '')
    input_keys("abc\C-k")
    assert_equal(@line_editor.line, 'abc')
    input_keys("\C-b\C-k")
    assert_equal(@line_editor.line, 'ab')
  end

  def test_em_kill_line
    input_keys("\C-u")
    assert_equal(@line_editor.line, '')
    input_keys("abc\C-u")
    assert_equal(@line_editor.line, '')
    input_keys("abc\C-b\C-u")
    assert_equal(@line_editor.line, 'c')
    input_keys("\C-u")
    assert_equal(@line_editor.line, 'c')
  end

  def test_ed_move_to_beg
    input_keys("abd\C-bc\C-a012")
    assert_equal(@line_editor.line, '012abcd')
    input_keys("\C-aABC")
    assert_equal(@line_editor.line, 'ABC012abcd')
    input_keys("\C-f" * 10 + "\C-aa")
    assert_equal(@line_editor.line, 'aABC012abcd')
  end

  def test_ed_move_to_end
    input_keys("abd\C-bc\C-e012")
    assert_equal(@line_editor.line, 'abcd012')
    input_keys("\C-eABC")
    assert_equal(@line_editor.line, 'abcd012ABC')
    input_keys("\C-b" * 10 + "\C-ea")
    assert_equal(@line_editor.line, 'abcd012ABCa')
  end

  def test_em_delete_or_list
    input_keys("ab\C-a\C-d")
    assert_equal(@line_editor.line, 'b')
  end

  def test_em_delete_or_list_for_mbchar
    input_keys("かき\C-a\C-d")
    assert_equal(@line_editor.line, 'き')
  end

  def test_em_delete_or_list_for_grapheme_clusters_by_plural_code_points
    input_keys("か\u3099き\u3099\C-a\C-d")
    assert_equal(@line_editor.line, "き\u3099")
  end
end
