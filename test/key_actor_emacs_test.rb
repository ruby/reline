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
end
