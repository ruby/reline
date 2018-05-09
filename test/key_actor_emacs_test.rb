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
end
