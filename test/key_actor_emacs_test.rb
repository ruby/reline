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

  def test_move_next_and_prev
    input_keys("abd\C-b\C-b\C-fc")
    assert_equal(@line_editor.line, 'abcd')
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
end
