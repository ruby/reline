require 'helper'

class Reline::KeyActor::ViInsert::Test < Reline::TestCase
  def setup
    @prompt = '> '
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::ViInsert, @prompt)
    @line_editor.retrieve_completion_block = Reline.method(:retrieve_completion_block)
  end

  def test_vi_command_mode
    input_keys("\C-[")
    assert_equal(Reline::KeyActor::ViCommand, @line_editor.instance_variable_get(:@key_actor))
  end

  def test_vi_command_mode_with_input
    input_keys("abc\C-[")
    assert_equal(Reline::KeyActor::ViCommand, @line_editor.instance_variable_get(:@key_actor))
    assert_equal('abc', @line_editor.line)
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

  def test_vi_delete_prev_char
    input_keys('ab')
    assert_equal(2, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-h")
    assert_equal(1, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(1, @line_editor.instance_variable_get(:@cursor))
    assert_equal(1, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('a', @line_editor.line)
  end

  def test_vi_delete_prev_char_for_mbchar
    input_keys('かき')
    assert_equal(6, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-h")
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('か', @line_editor.line)
  end

  def test_vi_delete_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_equal(12, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-h")
    assert_equal(6, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal("か\u3099", @line_editor.line)
  end

  def test_ed_delete_prev_word
    input_keys('abc def{bbb}ccc')
    assert_equal(15, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(15, @line_editor.instance_variable_get(:@cursor))
    assert_equal(15, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-w")
    assert_equal(12, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(12, @line_editor.instance_variable_get(:@cursor))
    assert_equal(12, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abc def{bbb}', @line_editor.line)
    input_keys("\C-w")
    assert_equal(8, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abc def{', @line_editor.line)
    input_keys("\C-w")
    assert_equal(4, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor))
    assert_equal(4, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abc ', @line_editor.line)
    input_keys("\C-w")
    assert_equal(0, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('', @line_editor.line)
  end

  def test_ed_delete_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_equal(39, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(27, @line_editor.instance_variable_get(:@cursor))
    assert_equal(27, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-w")
    assert_equal(30, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(21, @line_editor.instance_variable_get(:@cursor))
    assert_equal(21, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('あいう かきく{さしす}', @line_editor.line)
    input_keys("\C-w")
    assert_equal(20, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('あいう かきく{', @line_editor.line)
    input_keys("\C-w")
    assert_equal(10, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('あいう ', @line_editor.line)
    input_keys("\C-w")
    assert_equal(0, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('', @line_editor.line)
  end

  def test_ed_delete_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_equal(48, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(27, @line_editor.instance_variable_get(:@cursor))
    assert_equal(27, @line_editor.instance_variable_get(:@cursor_max))
    input_keys("\C-w")
    assert_equal(39, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(21, @line_editor.instance_variable_get(:@cursor))
    assert_equal(21, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal("あいう か\u3099き\u3099く\u3099{さしす}", @line_editor.line)
    input_keys("\C-w")
    assert_equal(29, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal("あいう か\u3099き\u3099く\u3099{", @line_editor.line)
    input_keys("\C-w")
    assert_equal(10, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('あいう ', @line_editor.line)
    input_keys("\C-w")
    assert_equal(0, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor))
    assert_equal(0, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('', @line_editor.line)
  end

  def test_ed_newline_with_cr
    input_keys('ab')
    assert_equal(2, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
    refute(@line_editor.finished?)
    input_keys("\C-m")
    assert_equal("ab\n", @line_editor.line)
    assert(@line_editor.finished?)
  end

  def test_ed_newline_with_lf
    input_keys('ab')
    assert_equal(2, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor))
    assert_equal(2, @line_editor.instance_variable_get(:@cursor_max))
    refute(@line_editor.finished?)
    input_keys("\C-j")
    assert_equal("ab\n", @line_editor.line)
    assert(@line_editor.finished?)
  end

  def test_completion_journey
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }
    }
    input_keys('foo')
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-n")
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-n")
    assert_equal(7, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar', @line_editor.line)
    input_keys("\C-n")
    assert_equal(11, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_baz', @line_editor.line)
    input_keys("\C-n")
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-n")
    assert_equal(7, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar', @line_editor.line)
    input_keys("_\C-n")
    assert_equal(8, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_', @line_editor.line)
    input_keys("\C-n")
    assert_equal(11, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_baz', @line_editor.line)
    input_keys("\C-n")
    assert_equal(8, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_', @line_editor.line)
  end

  def test_completion_journey_reverse
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }
    }
    input_keys('foo')
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-p")
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-p")
    assert_equal(11, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_baz', @line_editor.line)
    input_keys("\C-p")
    assert_equal(7, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor))
    assert_equal(7, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar', @line_editor.line)
    input_keys("\C-p")
    assert_equal(3, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor))
    assert_equal(3, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo', @line_editor.line)
    input_keys("\C-p")
    assert_equal(11, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_baz', @line_editor.line)
    input_keys("\C-h\C-p")
    assert_equal(10, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(10, @line_editor.instance_variable_get(:@cursor))
    assert_equal(10, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_ba', @line_editor.line)
    input_keys("\C-p")
    assert_equal(11, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor))
    assert_equal(11, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_baz', @line_editor.line)
    input_keys("\C-p")
    assert_equal(10, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(10, @line_editor.instance_variable_get(:@cursor))
    assert_equal(10, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('foo_bar_ba', @line_editor.line)
  end

  def test_completion_journey_in_middle_of_line
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }
    }
    input_keys('abcde fo ABCDE')
    assert_equal('abcde fo ABCDE', @line_editor.line)
    input_keys("\C-[" + 'h' * 5 + "i\C-n")
    assert_equal(8, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde fo ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(13, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(13, @line_editor.instance_variable_get(:@cursor))
    assert_equal(19, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(17, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(17, @line_editor.instance_variable_get(:@cursor))
    assert_equal(23, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar_baz ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(8, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(8, @line_editor.instance_variable_get(:@cursor))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde fo ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(13, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(13, @line_editor.instance_variable_get(:@cursor))
    assert_equal(19, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar ABCDE', @line_editor.line)
    input_keys("_\C-n")
    assert_equal(14, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor))
    assert_equal(20, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar_ ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(17, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(17, @line_editor.instance_variable_get(:@cursor))
    assert_equal(23, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar_baz ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(14, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(14, @line_editor.instance_variable_get(:@cursor))
    assert_equal(20, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar_ ABCDE', @line_editor.line)
    input_keys("\C-n")
    assert_equal(17, @line_editor.instance_variable_get(:@byte_pointer))
    assert_equal(17, @line_editor.instance_variable_get(:@cursor))
    assert_equal(23, @line_editor.instance_variable_get(:@cursor_max))
    assert_equal('abcde foo_bar_baz ABCDE', @line_editor.line)
  end
end
