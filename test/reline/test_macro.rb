require_relative 'helper'

class Reline::MacroTest < Reline::TestCase
  def setup
    Reline.send(:test_mode)
    @config = Reline::Config.new
    @encoding = Reline.core.encoding
    @line_editor = Reline::LineEditor.new(@config, @encoding)
    @output = @line_editor.output = File.open(IO::NULL, "w")
  end

  def teardown
    @output.close
    Reline.test_reset
  end

  def test_simple_input
    input_keys('abc')
    assert_equal 'abc', @line_editor.line
  end

  def test_alias
    class << @line_editor
      alias delete_char ed_delete_prev_char
    end
    input_keys('abc')
    assert_nothing_raised(ArgumentError) {
      input_key_by_symbol(:delete_char)
    }
    assert_equal 'ab', @line_editor.line
  end
end
