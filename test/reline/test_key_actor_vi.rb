require_relative 'helper'

class Reline::KeyActor::ViInsert::Test < Reline::TestCase
  def setup
    Reline.send(:test_mode)
    @prompt = '> '
    @config = Reline::Config.new
    @config.read_lines(<<~LINES.split(/(?<=\n)/))
      set editing-mode vi
    LINES
    @encoding = Reline.core.encoding
    @line_editor = Reline::LineEditor.new(@config, @encoding)
    @line_editor.reset(@prompt, encoding: @encoding)
  end

  def teardown
    Reline.test_reset
  end

  def test_vi_command_mode
    input_keys("\C-[")
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
  end

  def test_vi_command_mode_with_input
    input_keys("abc\C-[")
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    assert_line('abc')
  end

  def test_vi_insert
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys('i')
    assert_line('i')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("\C-[")
    assert_line('i')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('i')
    assert_line('i')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_add
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys('a')
    assert_line('a')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("\C-[")
    assert_line('a')
    assert_cursor(0)
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('a')
    assert_line('a')
    assert_cursor(1)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_insert_at_bol
    input_keys('I')
    assert_line('I')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("12345\C-[hh")
    assert_cursor_line('I12', '345')
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('I')
    assert_cursor_line('', 'I12345')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_add_at_eol
    input_keys('A')
    assert_line('A')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
    input_keys("12345\C-[hh")
    assert_cursor_line('A12', '345')
    assert_instance_of(Reline::KeyActor::ViCommand, @config.editing_mode)
    input_keys('A')
    assert_cursor_line('A12345', '')
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_ed_insert_one
    input_keys('a')
    assert_cursor_line('a', '')
  end

  def test_ed_insert_two
    input_keys('ab')
    assert_cursor_line('ab', '')
  end

  def test_ed_insert_mbchar_one
    input_keys('か')
    assert_cursor_line('か', '')
  end

  def test_ed_insert_mbchar_two
    input_keys('かき')
    assert_cursor_line('かき', '')
  end

  def test_ed_insert_for_mbchar_by_plural_code_points
    input_keys("か\u3099")
    assert_cursor_line("か\u3099", '')
  end

  def test_ed_insert_for_plural_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_cursor_line("か\u3099き\u3099", '')
  end

  def test_ed_next_char
    input_keys("abcdef\C-[0")
    assert_cursor_line('', 'abcdef')
    input_keys('l')
    assert_cursor_line('a', 'bcdef')
    input_keys('2l')
    assert_cursor_line('abc', 'def')
  end

  def test_ed_prev_char
    input_keys("abcdef\C-[")
    assert_cursor_line('abcde', 'f')
    input_keys('h')
    assert_cursor_line('abcd', 'ef')
    input_keys('2h')
    assert_cursor_line('ab', 'cdef')
  end

  def test_history
    Reline::HISTORY.concat(%w{abc 123 AAA})
    input_keys("\C-[")
    assert_cursor_line('', '')
    input_keys('k')
    assert_cursor_line('', 'AAA')
    input_keys('2k')
    assert_cursor_line('', 'abc')
    input_keys('j')
    assert_cursor_line('', '123')
    input_keys('2j')
    assert_cursor_line('', '')
  end

  def test_vi_paste_prev
    input_keys("abcde\C-[3h")
    assert_cursor_line('a', 'bcde')
    input_keys('P')
    assert_cursor_line('a', 'bcde')
    input_keys('d$')
    assert_cursor_line('', 'a')
    input_keys('P')
    assert_cursor_line('bcd', 'ea')
    input_keys('2P')
    assert_cursor_line('bcdbcdbcd', 'eeea')
  end

  def test_vi_paste_next
    input_keys("abcde\C-[3h")
    assert_cursor_line('a', 'bcde')
    input_keys('p')
    assert_cursor_line('a', 'bcde')
    input_keys('d$')
    assert_cursor_line('', 'a')
    input_keys('p')
    assert_cursor_line('abcd', 'e')
    input_keys('2p')
    assert_cursor_line('abcdebcdebcd', 'e')
  end

  def test_vi_paste_prev_for_mbchar
    input_keys("あいうえお\C-[3h")
    assert_cursor_line('あ', 'いうえお')
    input_keys('P')
    assert_cursor_line('あ', 'いうえお')
    input_keys('d$')
    assert_cursor_line('', 'あ')
    input_keys('P')
    assert_cursor_line('いうえ', 'おあ')
    input_keys('2P')
    assert_cursor_line('いうえいうえいうえ', 'おおおあ')
  end

  def test_vi_paste_next_for_mbchar
    input_keys("あいうえお\C-[3h")
    assert_cursor_line('あ', 'いうえお')
    input_keys('p')
    assert_cursor_line('あ', 'いうえお')
    input_keys('d$')
    assert_cursor_line('', 'あ')
    input_keys('p')
    assert_cursor_line('あいうえ', 'お')
    input_keys('2p')
    assert_cursor_line('あいうえおいうえおいうえ', 'お')
  end

  def test_vi_paste_prev_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099け\u3099こ\u3099\C-[3h")
    assert_cursor_line("か\u3099", "き\u3099く\u3099け\u3099こ\u3099")
    input_keys('P')
    assert_cursor_line("か\u3099", "き\u3099く\u3099け\u3099こ\u3099")
    input_keys('d$')
    assert_cursor_line('', "か\u3099")
    input_keys('P')
    assert_cursor_line("き\u3099く\u3099け\u3099", "こ\u3099か\u3099")
    input_keys('2P')
    assert_cursor_line("き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099き\u3099く\u3099け\u3099", "こ\u3099こ\u3099こ\u3099か\u3099")
  end

  def test_vi_paste_next_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099け\u3099こ\u3099\C-[3h")
    assert_cursor_line("か\u3099", "き\u3099く\u3099け\u3099こ\u3099")
    input_keys('p')
    assert_cursor_line("か\u3099", "き\u3099く\u3099け\u3099こ\u3099")
    input_keys('d$')
    assert_cursor_line('', "か\u3099")
    input_keys('p')
    assert_cursor_line("か\u3099き\u3099く\u3099け\u3099", "こ\u3099")
    input_keys('2p')
    assert_cursor_line("か\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099こ\u3099き\u3099く\u3099け\u3099", "こ\u3099")
  end

  def test_vi_prev_next_word
    input_keys("aaa b{b}b ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('w')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b}')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b{')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa b')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('b')
    assert_byte_pointer_size('')
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{')
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('3w')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('aaa b{b')
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('3b')
    assert_byte_pointer_size('')
    assert_cursor_max(13)
  end

  def test_vi_end_word
    input_keys("aaa   b{b}}}b   ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aa')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   ')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor_max(19)
    input_keys('e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor_max(19)
    input_keys('03e')
    assert_byte_pointer_size('aaa   b')
    assert_cursor_max(19)
    input_keys('3e')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor_max(19)
    input_keys('3e')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor_max(19)
  end

  def test_vi_prev_next_big_word
    input_keys("aaa b{b}b ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('W')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('B')
    assert_byte_pointer_size('')
    assert_cursor_max(13)
    input_keys('2W')
    assert_byte_pointer_size('aaa b{b}b ')
    assert_cursor_max(13)
    input_keys('2W')
    assert_byte_pointer_size('aaa b{b}b cc')
    assert_cursor_max(13)
    input_keys('2B')
    assert_byte_pointer_size('aaa ')
    assert_cursor_max(13)
    input_keys('2B')
    assert_byte_pointer_size('')
    assert_cursor_max(13)
  end

  def test_vi_end_big_word
    input_keys("aaa   b{b}}}b   ccc\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aa')
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}')
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor_max(19)
    input_keys('E')
    assert_byte_pointer_size('aaa   b{b}}}b   cc')
    assert_cursor_max(19)
  end

  def test_ed_quoted_insert
    input_keys("ab\C-v\C-acd")
    assert_cursor_line("ab\C-acd", '')
  end

  def test_ed_quoted_insert_with_vi_arg
    input_keys("ab\C-[3\C-v\C-aacd")
    assert_cursor_line("a\C-a\C-a\C-abcd", '')
  end

  def test_vi_replace_char
    input_keys("abcdef\C-[03l")
    assert_cursor_line('abc', 'def')
    input_keys('rz')
    assert_cursor_line('abc', 'zef')
    input_keys('2rx')
    assert_cursor_line('abcxx', 'f')
  end

  def test_vi_replace_char_with_mbchar
    input_keys("あいうえお\C-[0l")
    assert_cursor_line('あ', 'いうえお')
    input_keys('rx')
    assert_cursor_line('あ', 'xうえお')
    input_keys('l2ry')
    assert_cursor_line('あxyy', 'お')
  end

  def test_vi_next_char
    input_keys("abcdef\C-[0")
    assert_cursor_line('', 'abcdef')
    input_keys('fz')
    assert_cursor_line('', 'abcdef')
    input_keys('fe')
    assert_cursor_line('abcd', 'ef')
  end

  def test_vi_to_next_char
    input_keys("abcdef\C-[0")
    assert_cursor_line('', 'abcdef')
    input_keys('tz')
    assert_cursor_line('', 'abcdef')
    input_keys('te')
    assert_cursor_line('abc', 'def')
  end

  def test_vi_prev_char
    input_keys("abcdef\C-[")
    assert_cursor_line('abcde', 'f')
    input_keys('Fz')
    assert_cursor_line('abcde', 'f')
    input_keys('Fa')
    assert_cursor_line('', 'abcdef')
  end

  def test_vi_to_prev_char
    input_keys("abcdef\C-[")
    assert_cursor_line('abcde', 'f')
    input_keys('Tz')
    assert_cursor_line('abcde', 'f')
    input_keys('Ta')
    assert_cursor_line('a', 'bcdef')
  end

  def test_vi_delete_next_char
    input_keys("abc\C-[h")
    assert_cursor_line('a', 'bc')
    input_keys('x')
    assert_cursor_line('a', 'c')
    input_keys('x')
    assert_cursor_line('', 'a')
    input_keys('x')
    assert_cursor_line('', '')
    input_keys('x')
    assert_cursor_line('', '')
  end

  def test_vi_delete_next_char_for_mbchar
    input_keys("あいう\C-[h")
    assert_cursor_line('あ', 'いう')
    input_keys('x')
    assert_cursor_line('あ', 'う')
    input_keys('x')
    assert_cursor_line('', 'あ')
    input_keys('x')
    assert_cursor_line('', '')
    input_keys('x')
    assert_cursor_line('', '')
  end

  def test_vi_delete_next_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099\C-[h")
    assert_cursor_line("か\u3099", "き\u3099く\u3099")
    input_keys('x')
    assert_cursor_line("か\u3099", "く\u3099")
    input_keys('x')
    assert_cursor_line('', "か\u3099")
    input_keys('x')
    assert_cursor_line('', '')
    input_keys('x')
    assert_cursor_line('', '')
  end

  def test_vi_delete_prev_char
    input_keys('ab')
    assert_cursor_line('ab', '')
    input_keys("\C-h")
    assert_cursor_line('a', '')
  end

  def test_vi_delete_prev_char_for_mbchar
    input_keys('かき')
    assert_cursor_line('かき', '')
    input_keys("\C-h")
    assert_cursor_line('か', '')
  end

  def test_vi_delete_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_cursor_line("か\u3099き\u3099", '')
    input_keys("\C-h")
    assert_cursor_line("か\u3099", '')
  end

  def test_ed_delete_prev_char
    input_keys("abcdefg\C-[h")
    assert_cursor_line('abcde', 'fg')
    input_keys('X')
    assert_cursor_line('abcd', 'fg')
    input_keys('3X')
    assert_cursor_line('a', 'fg')
    input_keys('p')
    assert_cursor_line('afbc', 'dg')
  end

  def test_ed_delete_prev_word
    input_keys('abc def{bbb}ccc')
    assert_cursor_line('abc def{bbb}ccc', '')
    input_keys("\C-w")
    assert_cursor_line('abc def{bbb}', '')
    input_keys("\C-w")
    assert_cursor_line('abc def{', '')
    input_keys("\C-w")
    assert_cursor_line('abc ', '')
    input_keys("\C-w")
    assert_cursor_line('', '')
  end

  def test_ed_delete_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_cursor_line('あいう かきく{さしす}たちつ', '')
    input_keys("\C-w")
    assert_cursor_line('あいう かきく{さしす}', '')
    input_keys("\C-w")
    assert_cursor_line('あいう かきく{', '')
    input_keys("\C-w")
    assert_cursor_line('あいう ', '')
    input_keys("\C-w")
    assert_cursor_line('', '')
  end

  def test_ed_delete_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}たちつ", '')
    input_keys("\C-w")
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}", '')
    input_keys("\C-w")
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{", '')
    input_keys("\C-w")
    assert_cursor_line('あいう ', '')
    input_keys("\C-w")
    assert_cursor_line('', '')
  end

  def test_ed_newline_with_cr
    input_keys('ab')
    assert_cursor_line('ab', '')
    refute(@line_editor.finished?)
    input_keys("\C-m")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_ed_newline_with_lf
    input_keys('ab')
    assert_cursor_line('ab', '')
    refute(@line_editor.finished?)
    input_keys("\C-j")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_vi_list_or_eof
    input_keys("\C-d") # quit from inputing
    assert_line(nil)
    assert(@line_editor.finished?)
  end

  def test_vi_list_or_eof_with_non_empty_line
    input_keys('ab')
    assert_cursor_line('ab', '')
    refute(@line_editor.finished?)
    input_keys("\C-d")
    assert_line('ab')
    assert(@line_editor.finished?)
  end

  def test_completion_journey
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_cursor_line('foo', '')
    input_keys("\C-n")
    assert_cursor_line('foo_bar', '')
    input_keys("\C-n")
    assert_cursor_line('foo_bar_baz', '')
    input_keys("\C-n")
    assert_cursor_line('foo', '')
    input_keys("\C-n")
    assert_cursor_line('foo_bar', '')
    input_keys("_\C-n")
    assert_cursor_line('foo_bar_baz', '')
    input_keys("\C-n")
    assert_cursor_line('foo_bar_', '')
  end

  def test_completion_journey_reverse
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_cursor_line('foo', '')
    input_keys("\C-p")
    assert_cursor_line('foo_bar_baz', '')
    input_keys("\C-p")
    assert_cursor_line('foo_bar', '')
    input_keys("\C-p")
    assert_cursor_line('foo', '')
    input_keys("\C-p")
    assert_cursor_line('foo_bar_baz', '')
    input_keys("\C-h\C-p")
    assert_cursor_line('foo_bar_baz', '')
    input_keys("\C-p")
    assert_cursor_line('foo_bar_ba', '')
  end

  def test_completion_journey_in_middle_of_line
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('abcde fo ABCDE')
    assert_line('abcde fo ABCDE')
    input_keys("\C-[" + 'h' * 5 + "i\C-n")
    assert_cursor_line('abcde foo_bar', ' ABCDE')
    input_keys("\C-n")
    assert_cursor_line('abcde foo_bar_baz', ' ABCDE')
    input_keys("\C-n")
    assert_cursor_line('abcde fo', ' ABCDE')
    input_keys("\C-n")
    assert_cursor_line('abcde foo_bar', ' ABCDE')
    input_keys("_\C-n")
    assert_cursor_line('abcde foo_bar_baz', ' ABCDE')
    input_keys("\C-n")
    assert_cursor_line('abcde foo_bar_', ' ABCDE')
    input_keys("\C-n")
    assert_cursor_line('abcde foo_bar_baz', ' ABCDE')
  end

  def test_completion
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_cursor_line('foo', '')
    input_keys("\C-i")
    assert_cursor_line('foo_bar', '')
  end

  def test_completion_with_disable_completion
    @config.disable_completion = true
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_bar
        foo_bar_baz
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo')
    assert_cursor_line('foo', '')
    input_keys("\C-i")
    assert_cursor_line('foo', '')
  end

  def test_vi_first_print
    input_keys("abcde\C-[^")
    assert_byte_pointer_size('')
    assert_cursor_max(5)
    input_keys("0\C-ki")
    input_keys(" abcde\C-[^")
    assert_byte_pointer_size(' ')
    assert_cursor_max(6)
    input_keys("0\C-ki")
    input_keys("   abcde  ABCDE  \C-[^")
    assert_byte_pointer_size('   ')
    assert_cursor_max(17)
  end

  def test_ed_move_to_beg
    input_keys("abcde\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(5)
    input_keys("0\C-ki")
    input_keys(" abcde\C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(6)
    input_keys("0\C-ki")
    input_keys("   abcde  ABCDE  \C-[0")
    assert_byte_pointer_size('')
    assert_cursor_max(17)
  end

  def test_vi_delete_meta
    input_keys("aaa bbb ccc ddd eee\C-[02w")
    assert_cursor_line('aaa bbb ', 'ccc ddd eee')
    input_keys('dw')
    assert_cursor_line('aaa bbb ', 'ddd eee')
    input_keys('db')
    assert_cursor_line('aaa ', 'ddd eee')
  end

  def test_vi_delete_meta_with_vi_next_word_at_eol
    input_keys("foo bar\C-[0w")
    assert_cursor_line('foo ', 'bar')
    input_keys('w')
    assert_cursor_line('foo ba', 'r')
    input_keys('0dw')
    assert_cursor_line('', 'bar')
    input_keys('dw')
    assert_cursor_line('', '')
  end

  def test_vi_delete_meta_with_vi_next_char
    input_keys("aaa bbb ccc ___ ddd\C-[02w")
    assert_cursor_line('aaa bbb ', 'ccc ___ ddd')
    input_keys('df_')
    assert_cursor_line('aaa bbb ', '__ ddd')
  end

  def test_vi_delete_meta_with_arg
    input_keys("aaa bbb ccc\C-[02w")
    assert_cursor_line('aaa bbb ', 'ccc')
    input_keys('2dl')
    assert_cursor_line('aaa bbb ', 'c')
  end

  def test_vi_change_meta
    input_keys("aaa bbb ccc ddd eee\C-[02w")
    assert_cursor_line('aaa bbb ', 'ccc ddd eee')
    input_keys('cwaiueo')
    assert_cursor_line('aaa bbb aiueo', ' ddd eee')
    input_keys("\C-[")
    assert_cursor_line('aaa bbb aiue', 'o ddd eee')
    input_keys('cb')
    assert_cursor_line('aaa bbb ', 'o ddd eee')
  end

  def test_vi_change_meta_with_vi_next_word
    input_keys("foo  bar  baz\C-[0w")
    assert_cursor_line('foo  ', 'bar  baz')
    input_keys('cwhoge')
    assert_cursor_line('foo  hoge', '  baz')
    input_keys("\C-[")
    assert_cursor_line('foo  hog', 'e  baz')
  end

  def test_unimplemented_vi_command_should_be_no_op
    input_keys("abc\C-[h")
    assert_cursor_line('a', 'bc')
    input_keys('@')
    assert_cursor_line('a', 'bc')
  end

  def test_vi_yank
    input_keys("foo bar\C-[0")
    assert_cursor_line('', 'foo bar')
    input_keys('y3l')
    assert_cursor_line('', 'foo bar')
    input_keys('P')
    assert_cursor_line('fo', 'ofoo bar')
  end

  def test_vi_end_word_with_operator
    input_keys("foo bar\C-[0")
    assert_cursor_line('', 'foo bar')
    input_keys('de')
    assert_cursor_line('', ' bar')
    input_keys('de')
    assert_cursor_line('', '')
    input_keys('de')
    assert_cursor_line('', '')
  end

  def test_vi_end_big_word_with_operator
    input_keys("aaa   b{b}}}b\C-[0")
    assert_cursor_line('', 'aaa   b{b}}}b')
    input_keys('dE')
    assert_cursor_line('', '   b{b}}}b')
    input_keys('dE')
    assert_cursor_line('', '')
    input_keys('dE')
    assert_cursor_line('', '')
  end

  def test_vi_next_char_with_operator
    input_keys("foo bar\C-[0")
    assert_cursor_line('', 'foo bar')
    input_keys('df ')
    assert_cursor_line('', 'bar')
  end

  def test_pasting
    start_pasting
    input_keys('ab')
    finish_pasting
    input_keys('c')
    assert_cursor_line('abc', '')
  end

  def test_pasting_fullwidth
    start_pasting
    input_keys('あ')
    finish_pasting
    input_keys('い')
    assert_cursor_line('あい', '')
  end

  def test_ed_delete_next_char_at_eol
    input_keys('"あ"')
    assert_cursor_line('"あ"', '')
    input_keys("\C-[")
    assert_cursor_line('"あ', '"')
    input_keys('xa"')
    assert_cursor_line('"あ"', '')
  end

  def test_vi_kill_line_prev
    input_keys("\C-u", false)
    assert_cursor_line('', '')
    input_keys('abc')
    assert_cursor_line('abc', '')
    input_keys("\C-u", false)
    assert_cursor_line('', '')
    input_keys('abc')
    input_keys("\C-[\C-u", false)
    assert_cursor_line('', 'c')
    input_keys("\C-u", false)
    assert_cursor_line('', 'c')
  end

  def test_vi_change_to_eol
    input_keys("abcdef\C-[2hC")
    assert_line("abc")
    input_keys("\C-[0C")
    assert_line("")
    assert_cursor(0)
    assert_cursor_max(0)
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)
  end

  def test_vi_motion_operators
    assert_instance_of(Reline::KeyActor::ViInsert, @config.editing_mode)

    assert_nothing_raised do
      input_keys("test = { foo: bar }\C-[BBBldt}b")
    end
  end
end
