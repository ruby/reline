require_relative 'helper'

class Reline::KeyActor::Emacs::Test < Reline::TestCase
  def setup
    Reline.send(:test_mode)
    @prompt = '> '
    @config = Reline::Config.new # Emacs mode is default
    @config.autocompletion = false
    Reline::HISTORY.instance_variable_set(:@config, @config)
    Reline::HISTORY.clear
    @encoding = Reline.core.encoding
    @line_editor = Reline::LineEditor.new(@config, @encoding)
    @line_editor.reset(@prompt, encoding: @encoding)
  end

  def teardown
    Reline.test_reset
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

  def test_move_next_and_prev
    input_keys('abd')
    assert_cursor_line('abd', '')
    input_keys("\C-b", false)
    assert_cursor_line('ab', 'd')
    input_keys("\C-b", false)
    assert_cursor_line('a', 'bd')
    input_keys("\C-f", false)
    assert_cursor_line('ab', 'd')
    input_keys('c')
    assert_cursor_line('abc', 'd')
  end

  def test_move_next_and_prev_for_mbchar
    input_keys('かきけ')
    assert_cursor_line('かきけ', '')
    input_keys("\C-b", false)
    assert_cursor_line('かき', 'け')
    input_keys("\C-b", false)
    assert_cursor_line('か', 'きけ')
    input_keys("\C-f", false)
    assert_cursor_line('かき', 'け')
    input_keys('く')
    assert_cursor_line('かきく', 'け')
  end

  def test_move_next_and_prev_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099け\u3099")
    assert_cursor_line("か\u3099き\u3099け\u3099", '')
    input_keys("\C-b", false)
    assert_cursor_line("か\u3099き\u3099", "け\u3099")
    input_keys("\C-b", false)
    assert_cursor_line("か\u3099", "き\u3099け\u3099")
    input_keys("\C-f", false)
    assert_cursor_line("か\u3099き\u3099", "け\u3099")
    input_keys("く\u3099")
    assert_cursor_line("か\u3099き\u3099く\u3099", "け\u3099")
  end

  def test_move_to_beg_end
    input_keys('bcd')
    assert_cursor_line('bcd', '')
    input_keys("\C-a", false)
    assert_cursor_line('', 'bcd')
    input_keys('a')
    assert_cursor_line('a', 'bcd')
    input_keys("\C-e", false)
    assert_cursor_line('abcd', '')
    input_keys('e')
    assert_cursor_line('abcde', '')
  end

  def test_ed_newline_with_cr
    input_keys('ab')
    assert_cursor_line('ab', '')
    refute(@line_editor.finished?)
    input_keys("\C-m", false)
    assert_cursor_line('ab', '')
    assert(@line_editor.finished?)
  end

  def test_ed_newline_with_lf
    input_keys('ab')
    assert_cursor_line('ab', '')
    refute(@line_editor.finished?)
    input_keys("\C-j", false)
    assert_cursor_line('ab', '')
    assert(@line_editor.finished?)
  end

  def test_em_delete_prev_char
    input_keys('ab')
    assert_cursor_line('ab', '')
    input_keys("\C-h", false)
    assert_cursor_line('a', '')
  end

  def test_em_delete_prev_char_for_mbchar
    input_keys('かき')
    assert_cursor_line('かき', '')
    input_keys("\C-h", false)
    assert_cursor_line('か', '')
  end

  def test_em_delete_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_cursor_line("か\u3099き\u3099", '')
    input_keys("\C-h", false)
    assert_cursor_line("か\u3099", '')
  end

  def test_ed_quoted_insert
    input_keys("ab\C-v\C-acd")
    assert_cursor_line("ab\C-acd", '')
    input_keys("\C-q\C-b")
    assert_cursor_line("ab\C-acd\C-b", '')
  end

  def test_ed_kill_line
    input_keys("\C-k", false)
    assert_cursor_line('', '')
    input_keys('abc')
    assert_cursor_line('abc', '')
    input_keys("\C-k", false)
    assert_cursor_line('abc', '')
    input_keys("\C-b\C-k", false)
    assert_cursor_line('ab', '')
  end

  def test_em_kill_line
    @line_editor.input_key(Reline::Key.new(:em_kill_line, :em_kill_line, false))
    assert_cursor_line('', '')
    input_keys('abc')
    @line_editor.input_key(Reline::Key.new(:em_kill_line, :em_kill_line, false))
    assert_cursor_line('', '')
    input_keys('abc')
    input_keys("\C-b", false)
    @line_editor.input_key(Reline::Key.new(:em_kill_line, :em_kill_line, false))
    assert_cursor_line('', '')
    input_keys('abc')
    input_keys("\C-a", false)
    @line_editor.input_key(Reline::Key.new(:em_kill_line, :em_kill_line, false))
    assert_cursor_line('', '')
  end

  def test_ed_move_to_beg
    input_keys('abd')
    assert_cursor_line('abd', '')
    input_keys("\C-b", false)
    assert_cursor_line('ab', 'd')
    input_keys('c')
    assert_cursor_line('abc', 'd')
    input_keys("\C-a", false)
    assert_cursor_line('', 'abcd')
    input_keys('012')
    assert_cursor_line('012', 'abcd')
    input_keys("\C-a", false)
    assert_cursor_line('', '012abcd')
    input_keys('ABC')
    assert_cursor_line('ABC', '012abcd')
    input_keys("\C-f" * 10 + "\C-a", false)
    assert_cursor_line('', 'ABC012abcd')
    input_keys('a')
    assert_cursor_line('a', 'ABC012abcd')
  end

  def test_ed_move_to_beg_with_blank
    input_keys('  abc')
    assert_cursor_line('  abc', '')
    input_keys("\C-a", false)
    assert_cursor_line('', '  abc')
  end

  def test_ed_move_to_end
    input_keys('abd')
    assert_cursor_line('abd', '')
    input_keys("\C-b", false)
    assert_cursor_line('ab', 'd')
    input_keys('c')
    assert_cursor_line('abc', 'd')
    input_keys("\C-e", false)
    assert_cursor_line('abcd', '')
    input_keys('012')
    assert_cursor_line('abcd012', '')
    input_keys("\C-e", false)
    assert_cursor_line('abcd012', '')
    input_keys('ABC')
    assert_cursor_line('abcd012ABC', '')
    input_keys("\C-b" * 10 + "\C-e", false)
    assert_cursor_line('abcd012ABC', '')
    input_keys('a')
    assert_cursor_line('abcd012ABCa', '')
  end

  def test_em_delete
    input_keys('ab')
    assert_cursor_line('ab', '')
    input_keys("\C-a", false)
    assert_cursor_line('', 'ab')
    input_keys("\C-d", false)
    assert_cursor_line('', 'b')
  end

  def test_em_delete_for_mbchar
    input_keys('かき')
    assert_cursor_line('かき', '')
    input_keys("\C-a", false)
    assert_cursor_line('', 'かき')
    input_keys("\C-d", false)
    assert_cursor_line('', 'き')
  end

  def test_em_delete_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099")
    assert_cursor_line("か\u3099き\u3099", '')
    input_keys("\C-a", false)
    assert_cursor_line('', "か\u3099き\u3099")
    input_keys("\C-d", false)
    assert_cursor_line('', "き\u3099")
  end

  def test_em_delete_ends_editing
    input_keys("\C-d") # quit from inputing
    assert_nil(@line_editor.line)
    assert(@line_editor.finished?)
  end

  def test_ed_clear_screen
    refute(@line_editor.instance_variable_get(:@cleared))
    input_keys("\C-l", false)
    assert(@line_editor.instance_variable_get(:@cleared))
  end

  def test_ed_clear_screen_with_inputed
    input_keys('abc')
    input_keys("\C-b", false)
    refute(@line_editor.instance_variable_get(:@cleared))
    assert_cursor_line('ab', 'c')
    input_keys("\C-l", false)
    assert(@line_editor.instance_variable_get(:@cleared))
    assert_cursor_line('ab', 'c')
  end

  def test_key_delete
    input_keys('abc')
    assert_cursor_line('abc', '')
    @line_editor.input_key(Reline::Key.new(:key_delete, :key_delete, false))
    assert_cursor_line('abc', '')
  end

  def test_key_delete_does_not_end_editing
    @line_editor.input_key(Reline::Key.new(:key_delete, :key_delete, false))
    assert_cursor_line('', '')
    refute(@line_editor.finished?)
  end

  def test_key_delete_preserves_cursor
    input_keys('abc')
    input_keys("\C-b", false)
    assert_cursor_line('ab', 'c')
    @line_editor.input_key(Reline::Key.new(:key_delete, :key_delete, false))
    assert_cursor_line('ab', '')
  end

  def test_em_next_word
    assert_cursor_line('', '')
    input_keys('abc def{bbb}ccc')
    input_keys("\C-a\M-F", false)
    assert_cursor_line('abc', ' def{bbb}ccc')
    input_keys("\M-F", false)
    assert_cursor_line('abc def', '{bbb}ccc')
    input_keys("\M-F", false)
    assert_cursor_line('abc def{bbb', '}ccc')
    input_keys("\M-F", false)
    assert_cursor_line('abc def{bbb}ccc', '')
    input_keys("\M-F", false)
    assert_cursor_line('abc def{bbb}ccc', '')
  end

  def test_em_next_word_for_mbchar
    assert_cursor_line('', '')
    input_keys('あいう かきく{さしす}たちつ')
    input_keys("\C-a\M-F", false)
    assert_cursor_line('あいう', ' かきく{さしす}たちつ')
    input_keys("\M-F", false)
    assert_cursor_line('あいう かきく', '{さしす}たちつ')
    input_keys("\M-F", false)
    assert_cursor_line('あいう かきく{さしす', '}たちつ')
    input_keys("\M-F", false)
    assert_cursor_line('あいう かきく{さしす}たちつ', '')
    input_keys("\M-F", false)
    assert_cursor_line('あいう かきく{さしす}たちつ', '')
  end

  def test_em_next_word_for_mbchar_by_plural_code_points
    assert_cursor_line("", "")
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\C-a\M-F", false)
    assert_cursor_line("あいう", " か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\M-F", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099", "{さしす}たちつ")
    input_keys("\M-F", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす", "}たちつ")
    input_keys("\M-F", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}たちつ", "")
    input_keys("\M-F", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}たちつ", "")
  end

  def test_em_prev_word
    input_keys('abc def{bbb}ccc')
    assert_cursor_line('abc def{bbb}ccc', '')
    input_keys("\M-B", false)
    assert_cursor_line('abc def{bbb}', 'ccc')
    input_keys("\M-B", false)
    assert_cursor_line('abc def{', 'bbb}ccc')
    input_keys("\M-B", false)
    assert_cursor_line('abc ', 'def{bbb}ccc')
    input_keys("\M-B", false)
    assert_cursor_line('', 'abc def{bbb}ccc')
    input_keys("\M-B", false)
    assert_cursor_line('', 'abc def{bbb}ccc')
  end

  def test_em_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_cursor_line('あいう かきく{さしす}たちつ', '')
    input_keys("\M-B", false)
    assert_cursor_line('あいう かきく{さしす}', 'たちつ')
    input_keys("\M-B", false)
    assert_cursor_line('あいう かきく{', 'さしす}たちつ')
    input_keys("\M-B", false)
    assert_cursor_line('あいう ', 'かきく{さしす}たちつ')
    input_keys("\M-B", false)
    assert_cursor_line('', 'あいう かきく{さしす}たちつ')
    input_keys("\M-B", false)
    assert_cursor_line('', 'あいう かきく{さしす}たちつ')
  end

  def test_em_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}たちつ", "")
    input_keys("\M-B", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}", "たちつ")
    input_keys("\M-B", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{", "さしす}たちつ")
    input_keys("\M-B", false)
    assert_cursor_line("あいう ", "か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\M-B", false)
    assert_cursor_line("", "あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\M-B", false)
    assert_cursor_line("", "あいう か\u3099き\u3099く\u3099{さしす}たちつ")
  end

  def test_em_delete_next_word
    input_keys('abc def{bbb}ccc')
    input_keys("\C-a", false)
    assert_cursor_line('', 'abc def{bbb}ccc')
    input_keys("\M-d", false)
    assert_cursor_line('', ' def{bbb}ccc')
    input_keys("\M-d", false)
    assert_cursor_line('', '{bbb}ccc')
    input_keys("\M-d", false)
    assert_cursor_line('', '}ccc')
    input_keys("\M-d", false)
    assert_cursor_line('', '')
  end

  def test_em_delete_next_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    input_keys("\C-a", false)
    assert_cursor_line('', 'あいう かきく{さしす}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', ' かきく{さしす}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', '{さしす}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', '}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', '')
  end

  def test_em_delete_next_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\C-a", false)
    assert_cursor_line('', "あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\M-d", false)
    assert_cursor_line('', " か\u3099き\u3099く\u3099{さしす}たちつ")
    input_keys("\M-d", false)
    assert_cursor_line('', '{さしす}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', '}たちつ')
    input_keys("\M-d", false)
    assert_cursor_line('', '')
  end

  def test_ed_delete_prev_word
    input_keys('abc def{bbb}ccc')
    assert_cursor_line('abc def{bbb}ccc', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('abc def{bbb}', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('abc def{', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('abc ', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('', '')
  end

  def test_ed_delete_prev_word_for_mbchar
    input_keys('あいう かきく{さしす}たちつ')
    assert_cursor_line('あいう かきく{さしす}たちつ', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('あいう かきく{さしす}', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('あいう かきく{', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('あいう ', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('', '')
  end

  def test_ed_delete_prev_word_for_mbchar_by_plural_code_points
    input_keys("あいう か\u3099き\u3099く\u3099{さしす}たちつ")
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}たちつ", '')
    input_keys("\M-\C-H", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{さしす}", '')
    input_keys("\M-\C-H", false)
    assert_cursor_line("あいう か\u3099き\u3099く\u3099{", '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('あいう ', '')
    input_keys("\M-\C-H", false)
    assert_cursor_line('', '')
  end

  def test_ed_transpose_chars
    input_keys('abc')
    input_keys("\C-a", false)
    assert_cursor_line('', 'abc')
    input_keys("\C-t", false)
    assert_cursor_line('', 'abc')
    input_keys("\C-f\C-t", false)
    assert_cursor_line('ba', 'c')
    input_keys("\C-t", false)
    assert_cursor_line('bca', '')
    input_keys("\C-t", false)
    assert_cursor_line('bac', '')
  end

  def test_ed_transpose_chars_for_mbchar
    input_keys('あかさ')
    input_keys("\C-a", false)
    assert_cursor_line('', 'あかさ')
    input_keys("\C-t", false)
    assert_cursor_line('', 'あかさ')
    input_keys("\C-f\C-t", false)
    assert_cursor_line('かあ', 'さ')
    input_keys("\C-t", false)
    assert_cursor_line('かさあ', '')
    input_keys("\C-t", false)
    assert_cursor_line('かあさ', '')
  end

  def test_ed_transpose_chars_for_mbchar_by_plural_code_points
    input_keys("あか\u3099さ")
    input_keys("\C-a", false)
    assert_cursor_line('', "あか\u3099さ")
    input_keys("\C-t", false)
    assert_cursor_line('', "あか\u3099さ")
    input_keys("\C-f\C-t", false)
    assert_cursor_line("か\u3099あ", 'さ')
    input_keys("\C-t", false)
    assert_cursor_line("か\u3099さあ", '')
    input_keys("\C-t", false)
    assert_cursor_line("か\u3099あさ", '')
  end

  def test_ed_transpose_words
    input_keys('abc def')
    assert_cursor_line('abc def', '')
    input_keys("\M-t", false)
    assert_cursor_line('def abc', '')
    input_keys("\C-a\C-k", false)
    input_keys(' abc  def   ')
    input_keys("\C-b" * 4, false)
    assert_cursor_line(' abc  de', 'f   ')
    input_keys("\M-t", false)
    assert_cursor_line(' def  abc', '   ')
    input_keys("\C-a\C-k", false)
    input_keys(' abc  def   ')
    input_keys("\C-b" * 6, false)
    assert_cursor_line(' abc  ', 'def   ')
    input_keys("\M-t", false)
    assert_cursor_line(' def  abc', '   ')
    input_keys("\M-t", false)
    assert_cursor_line(' abc     def', '')
  end

  def test_ed_transpose_words_for_mbchar
    input_keys('あいう かきく')
    assert_cursor_line('あいう かきく', '')
    input_keys("\M-t", false)
    assert_cursor_line('かきく あいう', '')
    input_keys("\C-a\C-k", false)
    input_keys(' あいう  かきく   ')
    input_keys("\C-b" * 4, false)
    assert_cursor_line(' あいう  かき', 'く   ')
    input_keys("\M-t", false)
    assert_cursor_line(' かきく  あいう', '   ')
    input_keys("\C-a\C-k", false)
    input_keys(' あいう  かきく   ')
    input_keys("\C-b" * 6, false)
    assert_cursor_line(' あいう  ', 'かきく   ')
    input_keys("\M-t", false)
    assert_cursor_line(' かきく  あいう', '   ')
    input_keys("\M-t", false)
    assert_cursor_line(' あいう     かきく', '')
  end

  def test_ed_transpose_words_with_one_word
    input_keys('abc  ')
    assert_cursor_line('abc  ', '')
    input_keys("\M-t", false)
    assert_cursor_line('abc  ', '')
    input_keys("\C-b", false)
    assert_cursor_line('abc ', ' ')
    input_keys("\M-t", false)
    assert_cursor_line('abc ', ' ')
    input_keys("\C-b" * 2, false)
    assert_cursor_line('ab', 'c  ')
    input_keys("\M-t", false)
    assert_cursor_line('ab', 'c  ')
    input_keys("\M-t", false)
    assert_cursor_line('ab', 'c  ')
  end

  def test_ed_transpose_words_with_one_word_for_mbchar
    input_keys('あいう  ')
    assert_cursor_line('あいう  ', '')
    input_keys("\M-t", false)
    assert_cursor_line('あいう  ', '')
    input_keys("\C-b", false)
    assert_cursor_line('あいう ', ' ')
    input_keys("\M-t", false)
    assert_cursor_line('あいう ', ' ')
    input_keys("\C-b" * 2, false)
    assert_cursor_line('あい', 'う  ')
    input_keys("\M-t", false)
    assert_cursor_line('あい', 'う  ')
    input_keys("\M-t", false)
    assert_cursor_line('あい', 'う  ')
  end

  def test_ed_digit
    input_keys('0123')
    assert_cursor_line('0123', '')
  end

  def test_ed_next_and_prev_char
    input_keys('abc')
    assert_cursor_line('abc', '')
    input_keys("\C-b", false)
    assert_cursor_line('ab', 'c')
    input_keys("\C-b", false)
    assert_cursor_line('a', 'bc')
    input_keys("\C-b", false)
    assert_cursor_line('', 'abc')
    input_keys("\C-b", false)
    assert_cursor_line('', 'abc')
    input_keys("\C-f", false)
    assert_cursor_line('a', 'bc')
    input_keys("\C-f", false)
    assert_cursor_line('ab', 'c')
    input_keys("\C-f", false)
    assert_cursor_line('abc', '')
    input_keys("\C-f", false)
    assert_cursor_line('abc', '')
  end

  def test_ed_next_and_prev_char_for_mbchar
    input_keys('あいう')
    assert_cursor_line('あいう', '')
    input_keys("\C-b", false)
    assert_cursor_line('あい', 'う')
    input_keys("\C-b", false)
    assert_cursor_line('あ', 'いう')
    input_keys("\C-b", false)
    assert_cursor_line('', 'あいう')
    input_keys("\C-b", false)
    assert_cursor_line('', 'あいう')
    input_keys("\C-f", false)
    assert_cursor_line('あ', 'いう')
    input_keys("\C-f", false)
    assert_cursor_line('あい', 'う')
    input_keys("\C-f", false)
    assert_cursor_line('あいう', '')
    input_keys("\C-f", false)
    assert_cursor_line('あいう', '')
  end

  def test_ed_next_and_prev_char_for_mbchar_by_plural_code_points
    input_keys("か\u3099き\u3099く\u3099")
    assert_cursor_line("か\u3099き\u3099く\u3099", '')
    input_keys("\C-b", false)
    assert_cursor_line("か\u3099き\u3099", "く\u3099")
    input_keys("\C-b", false)
    assert_cursor_line("か\u3099", "き\u3099く\u3099")
    input_keys("\C-b", false)
    assert_cursor_line('', "か\u3099き\u3099く\u3099")
    input_keys("\C-b", false)
    assert_cursor_line('', "か\u3099き\u3099く\u3099")
    input_keys("\C-f", false)
    assert_cursor_line("か\u3099", "き\u3099く\u3099")
    input_keys("\C-f", false)
    assert_cursor_line("か\u3099き\u3099", "く\u3099")
    input_keys("\C-f", false)
    assert_cursor_line("か\u3099き\u3099く\u3099", '')
    input_keys("\C-f", false)
    assert_cursor_line("か\u3099き\u3099く\u3099", '')
  end

  def test_em_capitol_case
    input_keys('abc def{bbb}ccc')
    input_keys("\C-a\M-c", false)
    assert_cursor_line('Abc', ' def{bbb}ccc')
    input_keys("\M-c", false)
    assert_cursor_line('Abc Def', '{bbb}ccc')
    input_keys("\M-c", false)
    assert_cursor_line('Abc Def{Bbb', '}ccc')
    input_keys("\M-c", false)
    assert_cursor_line('Abc Def{Bbb}Ccc', '')
  end

  def test_em_capitol_case_with_complex_example
    input_keys('{}#*    AaA!!!cCc   ')
    input_keys("\C-a\M-c", false)
    assert_cursor_line('{}#*    Aaa', '!!!cCc   ')
    input_keys("\M-c", false)
    assert_cursor_line('{}#*    Aaa!!!Ccc', '   ')
    input_keys("\M-c", false)
    assert_cursor_line('{}#*    Aaa!!!Ccc   ', '')
  end

  def test_em_lower_case
    input_keys('AbC def{bBb}CCC')
    input_keys("\C-a\M-l", false)
    assert_cursor_line('abc', ' def{bBb}CCC')
    input_keys("\M-l", false)
    assert_cursor_line('abc def', '{bBb}CCC')
    input_keys("\M-l", false)
    assert_cursor_line('abc def{bbb', '}CCC')
    input_keys("\M-l", false)
    assert_cursor_line('abc def{bbb}ccc', '')
  end

  def test_em_lower_case_with_complex_example
    input_keys('{}#*    AaA!!!cCc   ')
    input_keys("\C-a\M-l", false)
    assert_cursor_line('{}#*    aaa', '!!!cCc   ')
    input_keys("\M-l", false)
    assert_cursor_line('{}#*    aaa!!!ccc', '   ')
    input_keys("\M-l", false)
    assert_cursor_line('{}#*    aaa!!!ccc   ', '')
  end

  def test_em_upper_case
    input_keys('AbC def{bBb}CCC')
    input_keys("\C-a\M-u", false)
    assert_cursor_line('ABC', ' def{bBb}CCC')
    input_keys("\M-u", false)
    assert_cursor_line('ABC DEF', '{bBb}CCC')
    input_keys("\M-u", false)
    assert_cursor_line('ABC DEF{BBB', '}CCC')
    input_keys("\M-u", false)
    assert_cursor_line('ABC DEF{BBB}CCC', '')
  end

  def test_em_upper_case_with_complex_example
    input_keys('{}#*    AaA!!!cCc   ')
    input_keys("\C-a\M-u", false)
    assert_cursor_line('{}#*    AAA', '!!!cCc   ')
    input_keys("\M-u", false)
    assert_cursor_line('{}#*    AAA!!!CCC', '   ')
    input_keys("\M-u", false)
    assert_cursor_line('{}#*    AAA!!!CCC   ', '')
  end

  def test_em_delete_or_list
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('fooo')
    assert_cursor_line('fooo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-b", false)
    assert_cursor_line('foo', 'o')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    @line_editor.input_key(Reline::Key.new(:em_delete_or_list, :em_delete_or_list, false))
    assert_cursor_line('foo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    @line_editor.input_key(Reline::Key.new(:em_delete_or_list, :em_delete_or_list, false))
    assert_cursor_line('foo', '')
    assert_equal(%w{foo_foo foo_bar foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
  end

  def test_completion_duplicated_list
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_foo
        foo_bar
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('foo_')
    assert_cursor_line('foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(%w{foo_foo foo_bar}, @line_editor.instance_variable_get(:@menu_info).list)
  end

  def test_completion
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('fo')
    assert_cursor_line('fo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(%w{foo_foo foo_bar foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
    input_keys('a')
    input_keys("\C-i", false)
    assert_cursor_line('foo_a', '')
    input_keys("\C-h", false)
    input_keys('b')
    input_keys("\C-i", false)
    assert_cursor_line('foo_ba', '')
  end

  def test_completion_with_indent
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('  fo')
    assert_cursor_line('  fo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('  foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('  foo_', '')
    assert_equal(%w{foo_foo foo_bar foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
  end

  def test_completion_with_indent_and_completer_quote_characters
    @line_editor.completion_proc = proc { |word|
      %w{
        "".foo_foo
        "".foo_bar
        "".foo_baz
        "".qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('  "".fo')
    assert_cursor_line('  "".fo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('  "".foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('  "".foo_', '')
    assert_equal(%w{"".foo_foo "".foo_bar "".foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
  end

  def test_completion_with_perfect_match
    @line_editor.completion_proc = proc { |word|
      %w{
        foo
        foo_bar
      }.map { |i|
        i.encode(@encoding)
      }
    }
    matched = nil
    @line_editor.dig_perfect_match_proc = proc { |m|
      matched = m
    }
    input_keys('fo')
    assert_cursor_line('fo', '')
    assert_equal(Reline::LineEditor::CompletionState::NORMAL, @line_editor.instance_variable_get(:@completion_state))
    assert_equal(nil, matched)
    input_keys("\C-i", false)
    assert_cursor_line('foo', '')
    assert_equal(Reline::LineEditor::CompletionState::MENU_WITH_PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal(nil, matched)
    input_keys("\C-i", false)
    assert_cursor_line('foo', '')
    assert_equal(Reline::LineEditor::CompletionState::PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal(nil, matched)
    input_keys("\C-i", false)
    assert_cursor_line('foo', '')
    assert_equal(Reline::LineEditor::CompletionState::PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal('foo', matched)
    matched = nil
    input_keys('_')
    input_keys("\C-i", false)
    assert_cursor_line('foo_bar', '')
    assert_equal(Reline::LineEditor::CompletionState::MENU_WITH_PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal(nil, matched)
    input_keys("\C-i", false)
    assert_cursor_line('foo_bar', '')
    assert_equal(Reline::LineEditor::CompletionState::PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal(nil, matched)
    input_keys("\C-i", false)
    assert_cursor_line('foo_bar', '')
    assert_equal(Reline::LineEditor::CompletionState::PERFECT_MATCH, @line_editor.instance_variable_get(:@completion_state))
    assert_equal('foo_bar', matched)
  end

  def test_completion_with_completion_ignore_case
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        Foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('fo')
    assert_cursor_line('fo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(%w{foo_foo foo_bar}, @line_editor.instance_variable_get(:@menu_info).list)
    @config.completion_ignore_case = true
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(%w{foo_foo foo_bar Foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
    input_keys('a')
    input_keys("\C-i", false)
    assert_cursor_line('foo_a', '')
    input_keys("\C-h", false)
    input_keys('b')
    input_keys("\C-i", false)
    assert_cursor_line('foo_ba', '')
  end

  def test_completion_in_middle_of_line
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }
    }
    input_keys('abcde fo ABCDE')
    assert_cursor_line('abcde fo ABCDE', '')
    input_keys("\C-b" * 6 + "\C-i", false)
    assert_cursor_line('abcde foo_', ' ABCDE')
    input_keys("\C-b" * 2 + "\C-i", false)
    assert_cursor_line('abcde foo_', 'o_ ABCDE')
  end

  def test_completion_with_nil_value
    @line_editor.completion_proc = proc { |word|
      %w{
        foo_foo
        foo_bar
        Foo_baz
        qux
      }.map { |i|
        i.encode(@encoding)
      }.prepend(nil)
    }
    @config.completion_ignore_case = true
    input_keys('fo')
    assert_cursor_line('fo', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(nil, @line_editor.instance_variable_get(:@menu_info))
    input_keys("\C-i", false)
    assert_cursor_line('foo_', '')
    assert_equal(%w{foo_foo foo_bar Foo_baz}, @line_editor.instance_variable_get(:@menu_info).list)
    input_keys('a')
    input_keys("\C-i", false)
    assert_cursor_line('foo_a', '')
    input_keys("\C-h", false)
    input_keys('b')
    input_keys("\C-i", false)
    assert_cursor_line('foo_ba', '')
  end

  def test_em_kill_region
    input_keys('abc   def{bbb}ccc   ddd   ')
    assert_cursor_line('abc   def{bbb}ccc   ddd   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('abc   def{bbb}ccc   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('abc   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('', '')
    input_keys("\C-w", false)
    assert_cursor_line('', '')
  end

  def test_em_kill_region_mbchar
    input_keys('あ   い   う{う}う   ')
    assert_cursor_line('あ   い   う{う}う   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('あ   い   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('あ   ', '')
    input_keys("\C-w", false)
    assert_cursor_line('', '')
  end

  def test_vi_search_prev
    Reline::HISTORY.concat(%w{abc 123 AAA})
    assert_cursor_line('', '')
    input_keys("\C-ra\C-j")
    assert_cursor_line('', 'abc')
  end

  def test_larger_histories_than_history_size
    history_size = @config.history_size
    @config.history_size = 2
    Reline::HISTORY.concat(%w{abc 123 AAA})
    assert_cursor_line('', '')
    input_keys("\C-p")
    assert_cursor_line('AAA', '')
    input_keys("\C-p")
    assert_cursor_line('123', '')
    input_keys("\C-p")
    assert_cursor_line('123', '')
  ensure
    @config.history_size = history_size
  end

  def test_search_history_to_back
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-r123")
    assert_cursor_line('1234', '')
    input_keys("\C-ha")
    assert_cursor_line('12aa', '')
    input_keys("\C-h3")
    assert_cursor_line('1235', '')
  end

  def test_search_history_to_front
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-s123")
    assert_cursor_line('1235', '')
    input_keys("\C-ha")
    assert_cursor_line('12aa', '')
    input_keys("\C-h3")
    assert_cursor_line('1234', '')
  end

  def test_search_history_front_and_back
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-s12")
    assert_cursor_line('1235', '')
    input_keys("\C-s")
    assert_cursor_line('12aa', '')
    input_keys("\C-r")
    assert_cursor_line('12aa', '')
    input_keys("\C-r")
    assert_cursor_line('1235', '')
  end

  def test_search_history_back_and_front
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-r12")
    assert_cursor_line('1234', '')
    input_keys("\C-r")
    assert_cursor_line('12aa', '')
    input_keys("\C-s")
    assert_cursor_line('12aa', '')
    input_keys("\C-s")
    assert_cursor_line('1234', '')
  end

  def test_search_history_to_back_in_the_middle_of_histories
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-p\C-p")
    assert_cursor_line('12aa', '')
    input_keys("\C-r123")
    assert_cursor_line('1235', '')
  end

  def test_search_history_twice
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-r123")
    assert_cursor_line('1234', '')
    input_keys("\C-r")
    assert_cursor_line('1235', '')
  end

  def test_search_history_by_last_determined
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-r123")
    assert_cursor_line('1234', '')
    input_keys("\C-j")
    assert_cursor_line('', '1234')
    input_keys("\C-k") # delete
    assert_cursor_line('', '')
    input_keys("\C-r")
    assert_cursor_line('', '')
    input_keys("\C-r")
    assert_cursor_line('1235', '')
  end

  def test_search_history_with_isearch_terminator
    @config.read_lines(<<~LINES.split(/(?<=\n)/))
      set isearch-terminators "XYZ"
    LINES
    Reline::HISTORY.concat([
      '1235', # old
      '12aa',
      '1234' # new
    ])
    assert_cursor_line('', '')
    input_keys("\C-r12a")
    assert_cursor_line('12aa', '')
    input_keys('Y')
    assert_cursor_line('', '12aa')
    input_keys('x')
    assert_cursor_line('x', '12aa')
  end

  def test_em_set_mark_and_em_exchange_mark
    input_keys('aaa bbb ccc ddd')
    assert_cursor_line('aaa bbb ccc ddd', '')
    input_keys("\C-a\M-F\M-F", false)
    assert_cursor_line('aaa bbb', ' ccc ddd')
    assert_equal(nil, @line_editor.instance_variable_get(:@mark_pointer))
    input_keys("\x00", false) # C-Space
    assert_cursor_line('aaa bbb', ' ccc ddd')
    assert_equal([7, 0], @line_editor.instance_variable_get(:@mark_pointer))
    input_keys("\C-a", false)
    assert_cursor_line('', 'aaa bbb ccc ddd')
    assert_equal([7, 0], @line_editor.instance_variable_get(:@mark_pointer))
    input_key_by_symbol(:em_exchange_mark)
    assert_cursor_line('aaa bbb', ' ccc ddd')
    assert_equal([0, 0], @line_editor.instance_variable_get(:@mark_pointer))
  end

  def test_em_exchange_mark_without_mark
    input_keys('aaa bbb ccc ddd')
    assert_cursor_line('aaa bbb ccc ddd', '')
    input_keys("\C-a\M-f", false)
    assert_cursor_line('aaa', ' bbb ccc ddd')
    assert_equal(nil, @line_editor.instance_variable_get(:@mark_pointer))
    input_key_by_symbol(:em_exchange_mark)
    assert_cursor_line('aaa', ' bbb ccc ddd')
    assert_equal(nil, @line_editor.instance_variable_get(:@mark_pointer))
  end

  def test_modify_lines_with_wrong_rs
    verbose, $VERBOSE = $VERBOSE, nil
    original_global_slash = $/
    $/ = 'b'
    $VERBOSE = verbose
    @line_editor.output_modifier_proc = proc { |output| Reline::Unicode.escape_for_print(output) }
    input_keys("abcdef\n")
    result = @line_editor.__send__(:modify_lines, @line_editor.whole_lines, @line_editor.finished?)
    $/ = nil
    assert_equal(['abcdef'], result)
  ensure
    $VERBOSE = nil
    $/ = original_global_slash
    $VERBOSE = verbose
  end

  def test_ed_search_prev_history
    Reline::HISTORY.concat([
      '12356', # old
      '12aaa',
      '12345' # new
    ])
    input_keys('123')
    # The ed_search_prev_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '45')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '56')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '56')
  end

  def test_ed_search_prev_history_with_empty
    Reline::HISTORY.concat([
      '12356', # old
      '12aaa',
      '12345' # new
    ])
    # The ed_search_prev_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12345')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12aaa')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12356')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12356')
  end

  def test_ed_search_prev_history_without_match
    Reline::HISTORY.concat([
      '12356', # old
      '12aaa',
      '12345' # new
    ])
    input_keys('ABC')
    # The ed_search_prev_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('ABC', '')
  end

  def test_ed_search_next_history
    Reline::HISTORY.concat([
      '12356', # old
      '12aaa',
      '12345' # new
    ])
    input_keys('123')
    # The ed_search_prev_history and ed_search_next_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '45')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '56')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('123', '56')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_cursor_line('123', '45')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_cursor_line('123', '45')
  end

  def test_ed_search_next_history_with_empty
    Reline::HISTORY.concat([
      '12356', # old
      '12aaa',
      '12345' # new
    ])
    # The ed_search_prev_history and ed_search_next_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12345')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12aaa')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_cursor_line('', '12356')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_cursor_line('', '12aaa')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_cursor_line('', '12345')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_cursor_line('', '')
  end

  # Unicode emoji test
  def test_ed_insert_for_include_zwj_emoji
    omit "This test is for UTF-8 but the locale is #{Reline.core.encoding}" if Reline.core.encoding != Encoding::UTF_8
    # U+1F468 U+200D U+1F469 U+200D U+1F467 U+200D U+1F466 is family: man, woman, girl, boy "👨‍👩‍👧‍👦"
    input_keys("\u{1F468}") # U+1F468 is man "👨"
    assert_cursor_line('👨', '')
    input_keys("\u200D") # U+200D is ZERO WIDTH JOINER
    assert_cursor_line('👨‍', '')
    input_keys("\u{1F469}") # U+1F469 is woman "👩"
    assert_cursor_line('👨‍👩', '')
    input_keys("\u200D") # U+200D is ZERO WIDTH JOINER
    assert_cursor_line('👨‍👩‍', '')
    input_keys("\u{1F467}") # U+1F467 is girl "👧"
    assert_cursor_line('👨‍👩‍👧', '')
    input_keys("\u200D") # U+200D is ZERO WIDTH JOINER
    assert_cursor_line('👨‍👩‍👧‍', '')
    input_keys("\u{1F466}") # U+1F466 is boy "👦"
    assert_cursor_line('👨‍👩‍👧‍👦', '')
    # U+1F468 U+200D U+1F469 U+200D U+1F467 U+200D U+1F466 is family: man, woman, girl, boy "👨‍👩‍👧‍👦"
    input_keys("\u{1F468 200D 1F469 200D 1F467 200D 1F466}")
    assert_cursor_line('👨‍👩‍👧‍👦👨‍👩‍👧‍👦', '')
  end

  def test_ed_insert_for_include_valiation_selector
    omit "This test is for UTF-8 but the locale is #{Reline.core.encoding}" if Reline.core.encoding != Encoding::UTF_8
    # U+0030 U+FE00 is DIGIT ZERO + VARIATION SELECTOR-1 "0︀"
    input_keys("\u0030") # U+0030 is DIGIT ZERO
    assert_cursor_line('0', '')
    input_keys("\uFE00") # U+FE00 is VARIATION SELECTOR-1
    assert_cursor_line('0︀', '')
  end

  def test_em_yank_pop
    input_keys("def hoge\C-w\C-b\C-f\C-w", false)
    assert_cursor_line('', '')
    input_keys("\C-y", false)
    assert_cursor_line('def ', '')
    input_keys("\M-\C-y", false)
    assert_cursor_line('hoge', '')
  end

  def test_em_kill_region_with_kill_ring
    input_keys("def hoge\C-b\C-b\C-b\C-b", false)
    assert_cursor_line('def ', 'hoge')
    input_keys("\C-k\C-w", false)
    assert_cursor_line('', '')
    input_keys("\C-y", false)
    assert_cursor_line('def hoge', '')
  end

  def test_ed_search_prev_next_history_in_multibyte
    Reline::HISTORY.concat([
      "def hoge\n  67890\n  12345\nend", # old
      "def aiu\n  0xDEADBEEF\nend",
      "def foo\n  12345\nend" # new
    ])
    @line_editor.multiline_on
    input_keys('  123')
    # The ed_search_prev_history doesn't have default binding
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_whole_lines(['def foo', '  12345', 'end'])
    assert_line_index(1)
    assert_whole_lines(['def foo', '  12345', 'end'])
    assert_cursor_line('  123', '45')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_line_index(2)
    assert_whole_lines(['def hoge', '  67890', '  12345', 'end'])
    assert_cursor_line('  123', '45')
    @line_editor.__send__(:ed_search_prev_history, "\C-p".ord)
    assert_line_index(2)
    assert_whole_lines(['def hoge', '  67890', '  12345', 'end'])
    assert_cursor_line('  123', '45')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_line_index(1)
    assert_whole_lines(['def foo', '  12345', 'end'])
    assert_cursor_line('  123', '45')
    @line_editor.__send__(:ed_search_next_history, "\C-n".ord)
    assert_line_index(1)
    assert_whole_lines(['def foo', '  12345', 'end'])
    assert_cursor_line('  123', '45')
  end

  def test_ignore_NUL_by_ed_quoted_insert
    input_keys(%Q{"\C-v\C-@"}, false)
    assert_cursor_line('""', '')
  end

  def test_ed_argument_digit_by_meta_num
    input_keys('abcdef')
    assert_cursor_line('abcdef', '')
    input_keys("\M-2", false)
    input_keys("\C-h", false)
    assert_cursor_line('abcd', '')
  end

  def test_halfwidth_kana_width_dakuten
    input_raw_keys('ｶﾞｷﾞｹﾞｺﾞ')
    assert_cursor_line('ｶﾞｷﾞｹﾞｺﾞ', '')
    input_keys("\C-b\C-b", false)
    assert_cursor_line('ｶﾞｷﾞ', 'ｹﾞｺﾞ')
    input_raw_keys('ｸﾞ', false)
    assert_cursor_line('ｶﾞｷﾞｸﾞ', 'ｹﾞｺﾞ')
  end

  def test_input_unknown_char
    input_keys('͸') # U+0378 (unassigned)
    assert_cursor_line('͸', '')
  end

  def test_unix_line_discard
    input_keys("\C-u", false)
    assert_cursor_line('', '')
    input_keys('abc')
    assert_cursor_line('abc', '')
    input_keys("\C-b\C-u", false)
    assert_cursor_line('', 'c')
    input_keys("\C-f\C-u", false)
    assert_cursor_line('', '')
  end
end
