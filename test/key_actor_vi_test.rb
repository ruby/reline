require 'helper'

class Reline::KeyActor::ViInsert::Test < Reline::TestCase
  def setup
    @prompt = '> '
    if defined?(RELINE_TEST_ENCODING)
      @line_editor = Reline::LineEditor.new(Reline::KeyActor::ViInsert, @prompt, RELINE_TEST_ENCODING)
    else
      @line_editor = Reline::LineEditor.new(Reline::KeyActor::ViInsert, @prompt)
    end
    @line_editor.retrieve_completion_block = Reline.method(:retrieve_completion_block)
  end

  def test_vi_command_mode
    input_keys("\C-[")
    assert_equal(Reline::KeyActor::ViCommand, @line_editor.instance_variable_get(:@key_actor))
  end

  def test_vi_command_mode_with_input
    input_keys("abc\C-[")
    assert_equal(Reline::KeyActor::ViCommand, @line_editor.instance_variable_get(:@key_actor))
    assert_line('abc')
  end

  def test_ed_insert_one
    input_keys('a')
    assert_line('a')
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(1)
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_line('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_line('か')
    assert_byte_pointer_size('か')
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_line('かき')
    assert_byte_pointer_size('かき')
    assert_cursor(4)
    assert_cursor_max(4)
  end

  def test_ed_insert_for_mbchar_by_plural_code_points
    input_keys("か\u3099")
    assert_line("か\u3099")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(2)
  end

  def test_ed_insert_for_plural_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_line("か\u3099き\u3099")
    assert_byte_pointer_size("か\u3099き\u3099")
    assert_cursor(4)
    assert_cursor_max(4)
  end

  def test_vi_delete_prev_char
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    input_keys("\C-h")
    assert_byte_pointer_size('a')
    assert_cursor(1)
    assert_cursor_max(1)
    assert_line('a')
  end

  def test_vi_delete_prev_char_for_mbchar
    input_keys('かき')
    assert_byte_pointer_size('かき')
    assert_cursor(4)
    assert_cursor_max(4)
    input_keys("\C-h")
    assert_byte_pointer_size('か')
    assert_cursor(2)
    assert_cursor_max(2)
    assert_line('か')
  end

  def test_vi_delete_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_byte_pointer_size("か\u3099き\u3099")
    assert_cursor(4)
    assert_cursor_max(4)
    input_keys("\C-h")
    assert_byte_pointer_size("か\u3099")
    assert_cursor(2)
    assert_cursor_max(2)
    assert_line("か\u3099")
  end

  def test_ed_delete_prev_word
    input_keys('abc def{bbb}ccc')
    assert_byte_pointer_size('abc def{bbb}ccc')
    assert_cursor(15)
    assert_cursor_max(15)
    input_keys("\C-w")
    assert_byte_pointer_size('abc def{bbb}')
    assert_cursor(12)
    assert_cursor_max(12)
    assert_line('abc def{bbb}')
    input_keys("\C-w")
    assert_byte_pointer_size('abc def{')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('abc def{')
    input_keys("\C-w")
    assert_byte_pointer_size('abc ')
    assert_cursor(4)
    assert_cursor_max(4)
    assert_line('abc ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_delete_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_byte_pointer_size('あいう かきく{さしす}たちつ')
    assert_cursor(27)
    assert_cursor_max(27)
    input_keys("\C-w")
    assert_byte_pointer_size('あいう かきく{さしす}')
    assert_cursor(21)
    assert_cursor_max(21)
    assert_line('あいう かきく{さしす}')
    input_keys("\C-w")
    assert_byte_pointer_size('あいう かきく{')
    assert_cursor(14)
    assert_cursor_max(14)
    assert_line('あいう かきく{')
    input_keys("\C-w")
    assert_byte_pointer_size('あいう ')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('あいう ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_delete_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_cursor(27)
    assert_cursor_max(27)
    input_keys("\C-w")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{さしす}")
    assert_cursor(21)
    assert_cursor_max(21)
    assert_line("あいう か\u3099き\u3099く\u3099{さしす}")
    input_keys("\C-w")
    assert_byte_pointer_size("あいう か\u3099き\u3099く\u3099{")
    assert_cursor(14)
    assert_cursor_max(14)
    assert_line("あいう か\u3099き\u3099く\u3099{")
    input_keys("\C-w")
    assert_byte_pointer_size('あいう ')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('あいう ')
    input_keys("\C-w")
    assert_byte_pointer_size('')
    assert_cursor(0)
    assert_cursor_max(0)
    assert_line('')
  end

  def test_ed_newline_with_cr
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    refute(@line_editor.finished?)
    input_keys("\C-m")
    assert_line("ab\n")
    assert(@line_editor.finished?)
  end

  def test_ed_newline_with_lf
    input_keys('ab')
    assert_byte_pointer_size('ab')
    assert_cursor(2)
    assert_cursor_max(2)
    refute(@line_editor.finished?)
    input_keys("\C-j")
    assert_line("ab\n")
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
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-n")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("_\C-n")
    assert_byte_pointer_size('foo_bar_')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('foo_bar_')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-n")
    assert_byte_pointer_size('foo_bar_')
    assert_cursor(8)
    assert_cursor_max(8)
    assert_line('foo_bar_')
  end

  def test_completion_journey_reverse
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }
    }
    input_keys('foo')
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar')
    assert_cursor(7)
    assert_cursor_max(7)
    assert_line('foo_bar')
    input_keys("\C-p")
    assert_byte_pointer_size('foo')
    assert_cursor(3)
    assert_cursor_max(3)
    assert_line('foo')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-h\C-p")
    assert_byte_pointer_size('foo_bar_ba')
    assert_cursor(10)
    assert_cursor_max(10)
    assert_line('foo_bar_ba')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_baz')
    assert_cursor(11)
    assert_cursor_max(11)
    assert_line('foo_bar_baz')
    input_keys("\C-p")
    assert_byte_pointer_size('foo_bar_ba')
    assert_cursor(10)
    assert_cursor_max(10)
    assert_line('foo_bar_ba')
  end

  def test_completion_journey_in_middle_of_line
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }
    }
    input_keys('abcde fo ABCDE')
    assert_line('abcde fo ABCDE')
    input_keys("\C-[" + 'h' * 5 + "i\C-n")
    assert_byte_pointer_size('abcde fo')
    assert_cursor(8)
    assert_cursor_max(14)
    assert_line('abcde fo ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar')
    assert_cursor(13)
    assert_cursor_max(19)
    assert_line('abcde foo_bar ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde fo')
    assert_cursor(8)
    assert_cursor_max(14)
    assert_line('abcde fo ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar')
    assert_cursor(13)
    assert_cursor_max(19)
    assert_line('abcde foo_bar ABCDE')
    input_keys("_\C-n")
    assert_byte_pointer_size('abcde foo_bar_')
    assert_cursor(14)
    assert_cursor_max(20)
    assert_line('abcde foo_bar_ ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_')
    assert_cursor(14)
    assert_cursor_max(20)
    assert_line('abcde foo_bar_ ABCDE')
    input_keys("\C-n")
    assert_byte_pointer_size('abcde foo_bar_baz')
    assert_cursor(17)
    assert_cursor_max(23)
    assert_line('abcde foo_bar_baz ABCDE')
  end
end
