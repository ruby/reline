require 'helper'

class Reline::KeyActor::ViInsert::Test < Reline::TestCase
  def setup
    @prompt = '> '
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::ViInsert, @prompt)
  end

  def test_ed_insert_one
    input_keys('a')
    assert_equal('a', @line_editor.line)
    assert_equal(1, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(1, @line_editor.instance_variable_get(:@cursor))
    assert_equal(1, @line_editor.instance_variable_get(:@cursor_max))
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_equal('ab', @line_editor.line)
    assert_equal(2, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_equal('か', @line_editor.line)
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_equal('かき', @line_editor.line)
    assert_equal(6, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor_max))
  end

  def test_ed_insert_for_mbchar_by_plural_code_points
    input_keys("か\u3099")
    assert_equal("か\u3099", @line_editor.line)
    assert_equal(6, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
  end

  def test_ed_insert_for_plural_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_equal("か\u3099き\u3099", @line_editor.line)
    assert_equal(12, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor_max))
  end
end
