require_relative 'helper'
require 'reline'

class Reline::ANSITest < Reline::TestCase
  def setup
    Reline.send(:test_mode, ansi: true)
    @config = Reline::Config.new
    Reline.core.io_gate.set_default_key_bindings(@config)
  end

  def teardown
    Reline.test_reset
  end

  def test_home
    assert_key_binding("\e[1~", :ed_move_to_beg) # Console (80x25)
    assert_key_binding("\e[H", :ed_move_to_beg) # KDE
    assert_key_binding("\e[7~", :ed_move_to_beg) # urxvt / exoterm
    assert_key_binding("\eOH", :ed_move_to_beg) # GNOME
  end

  def test_end
    assert_key_binding("\e[4~", :ed_move_to_end) # Console (80x25)
    assert_key_binding("\e[F", :ed_move_to_end) # KDE
    assert_key_binding("\e[8~", :ed_move_to_end) # urxvt / exoterm
    assert_key_binding("\eOF", :ed_move_to_end) # GNOME
  end

  def test_delete
    assert_key_binding("\e[3~", :key_delete)
  end

  def test_up_arrow
    assert_key_binding("\e[A", :ed_prev_history) # Console (80x25)
    assert_key_binding("\eOA", :ed_prev_history)
  end

  def test_down_arrow
    assert_key_binding("\e[B", :ed_next_history) # Console (80x25)
    assert_key_binding("\eOB", :ed_next_history)
  end

  def test_right_arrow
    assert_key_binding("\e[C", :ed_next_char) # Console (80x25)
    assert_key_binding("\eOC", :ed_next_char)
  end

  def test_left_arrow
    assert_key_binding("\e[D", :ed_prev_char) # Console (80x25)
    assert_key_binding("\eOD", :ed_prev_char)
  end

  # Ctrl+arrow and Meta+arrow
  def test_extended
    assert_key_binding("\e[1;5C", :em_next_word) # Ctrl+→
    assert_key_binding("\e[1;5D", :ed_prev_word) # Ctrl+←
    assert_key_binding("\e[1;3C", :em_next_word) # Meta+→
    assert_key_binding("\e[1;3D", :ed_prev_word) # Meta+←
    assert_key_binding("\e\e[C", :em_next_word) # Meta+→
    assert_key_binding("\e\e[D", :ed_prev_word) # Meta+←
  end

  def test_shift_tab
    assert_key_binding("\e[Z", :completion_journey_up, [:emacs, :vi_insert])
  end

  # A few emacs bindings that are always mapped
  def test_more_emacs
    assert_key_binding("\e ", :em_set_mark, [:emacs])
    assert_key_binding("\C-x\C-x", :em_exchange_mark, [:emacs])
  end

  # An ANSI gate over a pair of pipes, with a terminal on the far side
  # (a socket or a serial line in practice).
  def with_remote_terminal(terminal: true)
    in_r, in_w = IO.pipe
    out_r, out_w = IO.pipe
    yield Reline::ANSI.new(input: in_r, output: out_w, terminal: terminal), in_w, out_r
  ensure
    [in_r, in_w, out_r, out_w].each(&:close)
  end

  def test_remote_terminal_cursor_pos
    with_remote_terminal do |gate, keys, screen|
      assert_true gate.terminal?
      keys.write "\e[12;5R"
      pos = gate.cursor_pos
      assert_equal [4, 11], [pos.x, pos.y]
      assert_equal "\e[6n", screen.read_nonblock(100)
    end
  end

  def test_pipe_without_terminal_asks_nothing
    with_remote_terminal(terminal: nil) do |gate, keys, screen|
      assert_false gate.terminal?
      pos = gate.cursor_pos
      assert_equal [0, 0], [pos.x, pos.y]
      assert_raise(IO::WaitReadable) { screen.read_nonblock(1) }
    end
  end

  def test_remote_terminal_screen_size
    with_remote_terminal do |gate, _keys, _screen|
      gate.set_screen_size(30, 100)
      assert_equal [30, 100], gate.get_screen_size
    end
  end

  def test_remote_terminal_read_single_char
    with_remote_terminal do |gate, keys, _screen|
      keys.write "a"
      assert_equal "a", gate.read_single_char(1)
    end
  end
end
