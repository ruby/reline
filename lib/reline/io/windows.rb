class Reline::Windows < Reline::IO

  attr_writer :output

  def initialize
    @input_buf = []
    @output_buf = []

    @input = STDIN
    @output = STDOUT
    @console_output = STDOUT
    @hsg = nil
    @legacy_console = legacy_console?
  end

  def encoding
    Encoding::UTF_8
  end

  def win?
    true
  end

  def win_legacy_console?
    @legacy_console
  end

  def set_default_key_bindings(config)
    {
      [224, 72] => :ed_prev_history, # ↑
      [224, 80] => :ed_next_history, # ↓
      [224, 77] => :ed_next_char,    # →
      [224, 75] => :ed_prev_char,    # ←
      [224, 83] => :key_delete,      # Del
      [224, 71] => :ed_move_to_beg,  # Home
      [224, 79] => :ed_move_to_end,  # End
      [  0, 72] => :ed_prev_history, # ↑
      [  0, 80] => :ed_next_history, # ↓
      [  0, 77] => :ed_next_char,    # →
      [  0, 75] => :ed_prev_char,    # ←
      [  0, 83] => :key_delete,      # Del
      [  0, 71] => :ed_move_to_beg,  # Home
      [  0, 79] => :ed_move_to_end   # End
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
      config.add_default_key_binding_by_keymap(:vi_insert, key, func)
      config.add_default_key_binding_by_keymap(:vi_command, key, func)
    end

    {
      [27, 32] => :em_set_mark,             # M-<space>
      [24, 24] => :em_exchange_mark,        # C-x C-x
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
    end

    # Emulate ANSI key sequence.
    {
      [27, 91, 90] => :completion_journey_up, # S-Tab
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
      config.add_default_key_binding_by_keymap(:vi_insert, key, func)
    end
  end

  VK_RETURN = 0x0D
  VK_MENU = 0x12 # ALT key
  VK_LMENU = 0xA4
  VK_CONTROL = 0x11
  VK_SHIFT = 0x10
  VK_DIVIDE = 0x6F

  CAPSLOCK_ON = 0x0080
  ENHANCED_KEY = 0x0100
  LEFT_ALT_PRESSED = 0x0002
  LEFT_CTRL_PRESSED = 0x0008
  NUMLOCK_ON = 0x0020
  RIGHT_ALT_PRESSED = 0x0001
  RIGHT_CTRL_PRESSED = 0x0004
  SCROLLLOCK_ON = 0x0040
  SHIFT_PRESSED = 0x0010

  VK_TAB = 0x09
  VK_END = 0x23
  VK_HOME = 0x24
  VK_LEFT = 0x25
  VK_UP = 0x26
  VK_RIGHT = 0x27
  VK_DOWN = 0x28
  VK_DELETE = 0x2E

  private def legacy_console?
    @console_output.tty?(nil) && !@console_output.console_mode.virtual_terminal_processing?
  end

  def msys_tty?
    @input.tty?(:msys, :cygwin)
  end

  KEY_MAP = [
    # It's treated as Meta+Enter on Windows.
    [ { control_keys: :CTRL,  virtual_key_code: 0x0D }, "\e\r".bytes ],
    [ { control_keys: :SHIFT, virtual_key_code: 0x0D }, "\e\r".bytes ],

    # It's treated as Meta+Space on Windows.
    [ { control_keys: :CTRL,  char_code: 0x20 }, "\e ".bytes ],

    # Emulate getwch() key sequences.
    [ { control_keys: [], virtual_key_code: VK_UP },     [0, 72] ],
    [ { control_keys: [], virtual_key_code: VK_DOWN },   [0, 80] ],
    [ { control_keys: [], virtual_key_code: VK_RIGHT },  [0, 77] ],
    [ { control_keys: [], virtual_key_code: VK_LEFT },   [0, 75] ],
    [ { control_keys: [], virtual_key_code: VK_DELETE }, [0, 83] ],
    [ { control_keys: [], virtual_key_code: VK_HOME },   [0, 71] ],
    [ { control_keys: [], virtual_key_code: VK_END },    [0, 79] ],

    # Emulate ANSI key sequence.
    [ { control_keys: :SHIFT, virtual_key_code: VK_TAB }, [27, 91, 90] ],
  ]

  def process_key_event(repeat_count, virtual_key_code, virtual_scan_code, char_code, control_key_state)

    # high-surrogate
    if 0xD800 <= char_code and char_code <= 0xDBFF
      @hsg = char_code
      return
    end
    # low-surrogate
    if 0xDC00 <= char_code and char_code <= 0xDFFF
      if @hsg
        char_code = 0x10000 + (@hsg - 0xD800) * 0x400 + char_code - 0xDC00
        @hsg = nil
      else
        # no high-surrogate. ignored.
        return
      end
    else
      # ignore high-surrogate without low-surrogate if there
      @hsg = nil
    end

    key = KeyEventRecord.new(virtual_key_code, char_code, control_key_state)

    match = KEY_MAP.find { |args,| key.match?(**args) }
    unless match.nil?
      @output_buf.concat(match.last)
      return
    end

    # no char, only control keys
    return if key.char_code == 0 and key.control_keys.any?

    @output_buf.push("\e".ord) if key.control_keys.include?(:ALT) and !key.control_keys.include?(:CTRL)

    @output_buf.concat(key.char.bytes)
  end

  def check_input_event
    while @output_buf.empty?
      Reline.core.line_editor.handle_signal
      events = @input.console_input_events(80, timeout: 0.1)
      if events.empty?
        # prevent for background consolemode change
        @legacy_console = legacy_console?
        next
      end
      events.each do |event|
        case event[:type]
        when :window_buffer_size
          @winch_handler.()
        when :key
          if event[:key_down]
            process_key_event(
              event[:repeat_count],
              event[:virtual_key_code],
              event[:virtual_scan_code],
              event[:unicode_char],
              event[:control_key_state]
            )
          end
        end
      end
    end
  end

  def with_raw_input
    yield
  end

  def write(string)
    @output.write(string)
  end

  def buffered_output
    yield
  end

  def getc(_timeout_second)
    check_input_event
    @output_buf.shift
  end

  def ungetc(c)
    @output_buf.unshift(c)
  end

  def in_pasting?
    not empty_buffer?
  end

  def empty_buffer?
    @output_buf.empty? && !@input.input_pending?
  end

  def get_screen_size
    @console_output.winsize
  rescue SystemCallError
    [24, 80]
  end

  def cursor_pos
    row, column = @console_output.cursor
    Reline::CursorPos.new(column, row)
  rescue SystemCallError
    Reline::CursorPos.new(0, 0)
  end

  def move_cursor_column(val)
    @console_output.goto_column(val)
  end

  def move_cursor_up(val)
    if val > 0
      row, column = @console_output.cursor
      @console_output.goto([row - val, 0].max, column)
    elsif val < 0
      move_cursor_down(-val)
    end
  end

  def move_cursor_down(val)
    if val > 0
      row, column = @console_output.cursor
      rows, = @console_output.winsize
      @console_output.goto([row + val, rows - 1].min, column)
    elsif val < 0
      move_cursor_up(-val)
    end
  end

  def erase_after_cursor
    @console_output.erase_line(0)
  end

  # This only works when the cursor is at the bottom of the scroll range
  # For more details, see https://github.com/ruby/reline/pull/577#issuecomment-1646679623
  def scroll_down(x)
    return if x.zero?
    # We use `\n` instead of CSI + S because CSI + S would cause https://github.com/ruby/reline/issues/576
    @output.write "\n" * x
  end

  def clear_screen
    if @legacy_console
      @console_output.clear_screen
    else
      @output.write "\e[2J" "\e[H"
    end
  end

  def set_screen_size(rows, columns)
    raise NotImplementedError
  end

  def hide_cursor
    @console_output.hide_cursor
  end

  def show_cursor
    @console_output.show_cursor
  end

  def set_winch_handler(&handler)
    @winch_handler = handler
  end

  def prep
    # do nothing
    nil
  end

  def deprep(otio)
    # do nothing
  end

  def disable_auto_linewrap(setting = true, &block)
    mode = @console_output.console_mode
    unless mode.virtual_terminal_processing?
      if block
        wrap_at_eol = mode.wrap_at_eol_output?
        begin
          mode.wrap_at_eol_output = false
          @console_output.console_mode = mode
          block.call
        ensure
          mode.wrap_at_eol_output = wrap_at_eol
          @console_output.console_mode = mode
        end
      else
        mode.wrap_at_eol_output = !setting
        @console_output.console_mode = mode
      end
    else
      block.call if block
    end
  end

  class KeyEventRecord

    attr_reader :virtual_key_code, :char_code, :control_key_state, :control_keys

    def initialize(virtual_key_code, char_code, control_key_state)
      @virtual_key_code = virtual_key_code
      @char_code = char_code
      @control_key_state = control_key_state
      @enhanced = control_key_state & ENHANCED_KEY != 0

      (@control_keys = []).tap do |control_keys|
        # symbols must be sorted to make comparison is easier later on
        control_keys << :ALT   if control_key_state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) != 0
        control_keys << :CTRL  if control_key_state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) != 0
        control_keys << :SHIFT if control_key_state & SHIFT_PRESSED != 0
      end.freeze
    end

    def char
      @char_code.chr(Encoding::UTF_8)
    end

    def enhanced?
      @enhanced
    end

    # Verifies if the arguments match with this key event.
    # Nil arguments are ignored, but at least one must be passed as non-nil.
    # To verify that no control keys were pressed, pass an empty array: `control_keys: []`.
    def match?(control_keys: nil, virtual_key_code: nil, char_code: nil)
      raise ArgumentError, 'No argument was passed to match key event' if control_keys.nil? && virtual_key_code.nil? && char_code.nil?

      (control_keys.nil? || [*control_keys].sort == @control_keys) &&
      (virtual_key_code.nil? || @virtual_key_code == virtual_key_code) &&
      (char_code.nil? || char_code == @char_code)
    end

  end
end
