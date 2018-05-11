require 'helper'

class Reline::KeyActor::Emacs::Test < Test::Unit::TestCase
  def setup
    @prompt = '> '
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::Emacs, @prompt)
  end

  def test_ed_insert_one
    @line_editor.input_key('a'.ord)
    assert_equal(@line_editor.line, 'a')
  end

  def test_move_next_and_prev
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key('d'.ord)
    @line_editor.input_key("\C-b".ord)
    @line_editor.input_key("\C-b".ord)
    @line_editor.input_key("\C-f".ord)
    @line_editor.input_key('c'.ord)
    assert_equal(@line_editor.line, 'abcd')
  end

  def test_move_to_beg_end
    @line_editor.input_key('b'.ord)
    @line_editor.input_key('c'.ord)
    @line_editor.input_key('d'.ord)
    @line_editor.input_key("\C-a".ord)
    @line_editor.input_key('a'.ord)
    @line_editor.input_key("\C-e".ord)
    @line_editor.input_key('e'.ord)
    assert_equal(@line_editor.line, 'abcde')
  end

  def test_newline
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key("\C-m".ord)
    assert_equal(@line_editor.line, "ab\n")
    assert(@line_editor.finished?)
  end

  def test_delete_prev_char
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key("\C-h".ord)
    assert_equal(@line_editor.line, 'a')
  end

  def test_ed_kill_line
    @line_editor.input_key("\C-k".ord)
    assert_equal(@line_editor.line, '')
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key('c'.ord)
    @line_editor.input_key("\C-k".ord)
    assert_equal(@line_editor.line, 'abc')
    @line_editor.input_key("\C-b".ord)
    @line_editor.input_key("\C-k".ord)
    assert_equal(@line_editor.line, 'ab')
  end

  def test_em_kill_line
    @line_editor.input_key("\C-u".ord)
    assert_equal(@line_editor.line, '')
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key('c'.ord)
    @line_editor.input_key("\C-u".ord)
    assert_equal(@line_editor.line, '')
    @line_editor.input_key('a'.ord)
    @line_editor.input_key('b'.ord)
    @line_editor.input_key('c'.ord)
    @line_editor.input_key("\C-b".ord)
    @line_editor.input_key("\C-u".ord)
    assert_equal(@line_editor.line, 'c')
    @line_editor.input_key("\C-u".ord)
    assert_equal(@line_editor.line, 'c')
  end
end
