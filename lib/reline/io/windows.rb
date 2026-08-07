require 'fiddle/import'

class Reline::Windows < Reline::IO
  ANSI_CURSOR_KEY_BINDINGS = {
    # Up
    'A' => [:ed_prev_history, {}],
    # Down
    'B' => [:ed_next_history, {}],
    # Right
    'C' => [:ed_next_char, { ctrl: :em_next_word, meta: :em_next_word }],
    # Left
    'D' => [:ed_prev_char, { ctrl: :ed_prev_word, meta: :ed_prev_word }],
    # End
    'F' => [:ed_move_to_end, {}],
    # Home
    'H' => [:ed_move_to_beg, {}],
  }

  attr_writer :output

  def initialize
    @input_buf = []
    @output_buf = []

    @output = STDOUT
    @hsg = nil
    @getwch = Win32API.new('msvcrt', '_getwch', [], 'I')
    @kbhit = Win32API.new('msvcrt', '_kbhit', [], 'I')
    @GetKeyState = Win32API.new('user32', 'GetKeyState', ['L'], 'L')
    @MapVirtualKeyA = Win32API.new('user32', 'MapVirtualKeyA', ['L', 'L'], 'L')
    @ToUnicode = Win32API.new('user32', 'ToUnicode', ['I', 'I', 'P', 'P', 'I', 'I'], 'I')
    @GetConsoleScreenBufferInfo = Win32API.new('kernel32', 'GetConsoleScreenBufferInfo', ['L', 'P'], 'L')
    @SetConsoleCursorPosition = Win32API.new('kernel32', 'SetConsoleCursorPosition', ['L', 'L'], 'L')
    @GetStdHandle = Win32API.new('kernel32', 'GetStdHandle', ['L'], 'L')
    @FillConsoleOutputCharacter = Win32API.new('kernel32', 'FillConsoleOutputCharacter', ['L', 'L', 'L', 'L', 'P'], 'L')
    @ScrollConsoleScreenBuffer = Win32API.new('kernel32', 'ScrollConsoleScreenBuffer', ['L', 'P', 'P', 'L', 'P'], 'L')
    @hConsoleHandle = @GetStdHandle.call(STD_OUTPUT_HANDLE)
    @hConsoleInputHandle = @GetStdHandle.call(STD_INPUT_HANDLE)
    @GetNumberOfConsoleInputEvents = Win32API.new('kernel32', 'GetNumberOfConsoleInputEvents', ['L', 'P'], 'L')
    @ReadConsoleInputW = Win32API.new('kernel32', 'ReadConsoleInputW', ['L', 'P', 'L', 'P'], 'L')
    @GetFileType = Win32API.new('kernel32', 'GetFileType', ['L'], 'L')
    @GetFileInformationByHandleEx = Win32API.new('kernel32', 'GetFileInformationByHandleEx', ['L', 'I', 'P', 'L'], 'I')
    @FillConsoleOutputAttribute = Win32API.new('kernel32', 'FillConsoleOutputAttribute', ['L', 'L', 'L', 'L', 'P'], 'L')
    @SetConsoleCursorInfo = Win32API.new('kernel32', 'SetConsoleCursorInfo', ['L', 'P'], 'L')

    @GetConsoleMode = Win32API.new('kernel32', 'GetConsoleMode', ['L', 'P'], 'L')
    @SetConsoleMode = Win32API.new('kernel32', 'SetConsoleMode', ['L', 'L'], 'L')
    @WaitForSingleObject = Win32API.new('kernel32', 'WaitForSingleObject', ['L', 'L'], 'L')

    # Win32API does not have pointer size integer.
    # Current process pseudo handle (-1)LL seems to fail to be passed to DuplicateHandle.
    # @GetCurrentProcess = Win32API.new('kernel32', 'GetCurrentProcess', [], 'L')
    @GetCurrentProcessId = Win32API.new('kernel32', 'GetCurrentProcessId', [], 'L')
    @OpenProcess = Win32API.new('kernel32', 'OpenProcess', ['L', 'L', 'L'], 'L')
    @CloseHandle = Win32API.new('kernel32', 'CloseHandle', ['L'], 'L')
    @DuplicateHandle = Win32API.new('kernel32', 'DuplicateHandle', ['L', 'L', 'L', 'P', 'I', 'I', 'I'], 'L')

    current_process_handle = @OpenProcess.call(
      0x0040,  # PROCESS_DUP_HANDLE
      0,       # bInheritHandle
      @GetCurrentProcessId.call()
    )
    duplicate_handle = proc { |handle|
      dupHandle = "\0" * 8
      @DuplicateHandle.call(
        current_process_handle,
        handle,
        current_process_handle,
        dupHandle,
        0,  # dwDesiredAccess
        0,  # bInheritHandle
        2   # dwOptions = DUPLICATE_SAME_ACCESS
      )
      dupHandle.unpack1("J")
    }
    if (dup = duplicate_handle.call(@hConsoleHandle)) != 0
      @hConsoleHandle = dup
      at_exit { @CloseHandle.call(@hConsoleHandle) }
    end
    if (dup = duplicate_handle.call(@hConsoleInputHandle)) != 0
      @hConsoleInputHandle = dup
      at_exit { @CloseHandle.call(@hConsoleInputHandle) }
    end
    @CloseHandle.call(current_process_handle)

    @legacy_console = getconsolemode & ENABLE_VIRTUAL_TERMINAL_PROCESSING == 0
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
    # set_bracketed_paste_key_bindings(config)
    set_default_key_bindings_ansi_cursor(config)
    set_default_key_bindings_comprehensive_list(config)
    {
      [27, 91, 90] => :completion_journey_up, # S-Tab
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
      config.add_default_key_binding_by_keymap(:vi_insert, key, func)
    end
    {
      # default bindings
      [27, 32] => :em_set_mark,             # M-<space>
      [24, 24] => :em_exchange_mark,        # C-x C-x
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
    end
  end

  def set_bracketed_paste_key_bindings(config)
    [:emacs, :vi_insert, :vi_command].each do |keymap|
      config.add_default_key_binding_by_keymap(keymap, START_BRACKETED_PASTE.bytes, :bracketed_paste_start)
    end
  end

  def set_default_key_bindings_ansi_cursor(config)
    ANSI_CURSOR_KEY_BINDINGS.each do |char, (default_func, modifiers)|
      bindings = [
        ["\e[#{char}", default_func], # CSI + char
        ["\eO#{char}", default_func] # SS3 + char, application cursor key mode
      ]
      if modifiers[:ctrl]
        # CSI + ctrl_key_modifier + char
        bindings << ["\e[1;5#{char}", modifiers[:ctrl]]
      end
      if modifiers[:meta]
        # CSI + meta_key_modifier + char
        bindings << ["\e[1;3#{char}", modifiers[:meta]]
        # Meta(ESC) + CSI + char
        bindings << ["\e\e[#{char}", modifiers[:meta]]
      end
      bindings.each do |sequence, func|
        key = sequence.bytes
        config.add_default_key_binding_by_keymap(:emacs, key, func)
        config.add_default_key_binding_by_keymap(:vi_insert, key, func)
        config.add_default_key_binding_by_keymap(:vi_command, key, func)
      end
    end
  end

  def set_default_key_bindings_comprehensive_list(config)
    {
      # xterm
      [27, 91, 51, 126] => :key_delete, # kdch1
      [27, 91, 53, 126] => :ed_search_prev_history, # kpp
      [27, 91, 54, 126] => :ed_search_next_history, # knp

      # Console (80x25)
      [27, 91, 49, 126] => :ed_move_to_beg, # Home
      [27, 91, 52, 126] => :ed_move_to_end, # End

      # urxvt / exoterm
      [27, 91, 55, 126] => :ed_move_to_beg, # Home
      [27, 91, 56, 126] => :ed_move_to_end, # End
    }.each_pair do |key, func|
      config.add_default_key_binding_by_keymap(:emacs, key, func)
      config.add_default_key_binding_by_keymap(:vi_insert, key, func)
      config.add_default_key_binding_by_keymap(:vi_command, key, func)
    end
  end

  if defined? JRUBY_VERSION
    require 'win32api'
  else
    class Win32API
      DLL = {}
      TYPEMAP = {"0" => Fiddle::TYPE_VOID, "S" => Fiddle::TYPE_VOIDP, "I" => Fiddle::TYPE_LONG}
      POINTER_TYPE = Fiddle::SIZEOF_VOIDP == Fiddle::SIZEOF_LONG_LONG ? 'q*' : 'l!*'

      WIN32_TYPES = "VPpNnLlIi"
      DL_TYPES = "0SSI"

      def initialize(dllname, func, import, export = "0", calltype = :stdcall)
        @proto = [import].join.tr(WIN32_TYPES, DL_TYPES).sub(/^(.)0*$/, '\1')
        import = @proto.chars.map {|win_type| TYPEMAP[win_type.tr(WIN32_TYPES, DL_TYPES)]}
        export = TYPEMAP[export.tr(WIN32_TYPES, DL_TYPES)]
        calltype = Fiddle::Importer.const_get(:CALL_TYPE_TO_ABI)[calltype]

        handle = DLL[dllname] ||=
                 begin
                   Fiddle.dlopen(dllname)
                 rescue Fiddle::DLError
                   raise unless File.extname(dllname).empty?
                   Fiddle.dlopen(dllname + ".dll")
                 end

        @func = Fiddle::Function.new(handle[func], import, export, calltype)
      rescue Fiddle::DLError => e
        raise LoadError, e.message, e.backtrace
      end

      def call(*args)
        import = @proto.split("")
        args.each_with_index do |x, i|
          args[i], = [x == 0 ? nil : +x].pack("p").unpack(POINTER_TYPE) if import[i] == "S"
          args[i], = [x].pack("I").unpack("i") if import[i] == "I"
        end
        ret, = @func.call(*args)
        return ret || 0
      end
    end
  end

  VK_RETURN = 0x0D
  VK_SHIFT = 0x10
  VK_CONTROL = 0x11
  VK_MENU = 0x12 # ALT key
  VK_CAPITAL = 0x14
  VK_LSHIFT = 0xA0
  VK_RSHIFT = 0xA1
  VK_LCONTROL = 0xA2
  VK_RCONTROL = 0xA3
  VK_LMENU = 0xA4
  VK_RMENU = 0xA5

  KEY_EVENT = 0x01
  WINDOW_BUFFER_SIZE_EVENT = 0x04

  CAPSLOCK_ON = 0x0080
  ENHANCED_KEY = 0x0100
  LEFT_ALT_PRESSED = 0x0002
  LEFT_CTRL_PRESSED = 0x0008
  NUMLOCK_ON = 0x0020
  RIGHT_ALT_PRESSED = 0x0001
  RIGHT_CTRL_PRESSED = 0x0004
  SCROLLLOCK_ON = 0x0040
  SHIFT_PRESSED = 0x0010

  ALT_PRESSED = LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED
  CTRL_PRESSED = LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED
  SAC_MASK = SHIFT_PRESSED | ALT_PRESSED | CTRL_PRESSED

  VK_TAB = 0x09
  VK_CLEAR = 0x0C
  VK_PRIOR = 0x21
  VK_NEXT = 0x22
  VK_END = 0x23
  VK_HOME = 0x24
  VK_LEFT = 0x25
  VK_UP = 0x26
  VK_RIGHT = 0x27
  VK_DOWN = 0x28
  VK_INSERT = 0x2D
  VK_DELETE = 0x2E

  VK_NUMPAD0 = 0x60
  VK_NUMPAD1 = 0x61
  VK_NUMPAD2 = 0x62
  VK_NUMPAD3 = 0x63
  VK_NUMPAD4 = 0x64
  VK_NUMPAD5 = 0x65
  VK_NUMPAD6 = 0x66
  VK_NUMPAD7 = 0x67
  VK_NUMPAD8 = 0x68
  VK_NUMPAD9 = 0x69
  VK_DECIMAL = 0x6E
  VK_F1 = 0x70
  VK_F2 = 0x71
  VK_F3 = 0x72
  VK_F4 = 0x73
  VK_F5 = 0x74
  VK_F6 = 0x75
  VK_F7 = 0x76
  VK_F8 = 0x77
  VK_F9 = 0x78
  VK_F10 = 0x79
  VK_F11 = 0x7A
  VK_F12 = 0x7B

  CSI = "\e["
  SS3 = "\eO"

  STD_INPUT_HANDLE = -10
  STD_OUTPUT_HANDLE = -11
  FILE_TYPE_PIPE = 0x0003
  FILE_NAME_INFO = 2
  ENABLE_WRAP_AT_EOL_OUTPUT = 2
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = 4

  private def getconsolemode
    mode = +"\0\0\0\0"
    @GetConsoleMode.call(@hConsoleHandle, mode)
    mode.unpack1('L')
  end

  private def setconsolemode(mode)
    @SetConsoleMode.call(@hConsoleHandle, mode)
  end

  #if @legacy_console
  #  setconsolemode(getconsolemode() | ENABLE_VIRTUAL_TERMINAL_PROCESSING)
  #  @legacy_console = (getconsolemode() & ENABLE_VIRTUAL_TERMINAL_PROCESSING == 0)
  #end

  def msys_tty?(io = @hConsoleInputHandle)
    # check if fd is a pipe
    if @GetFileType.call(io) != FILE_TYPE_PIPE
      return false
    end

    bufsize = 1024
    p_buffer = "\0" * bufsize
    res = @GetFileInformationByHandleEx.call(io, FILE_NAME_INFO, p_buffer, bufsize - 2)
    return false if res == 0

    # get pipe name: p_buffer layout is:
    #   struct _FILE_NAME_INFO {
    #     DWORD FileNameLength;
    #     WCHAR FileName[1];
    #   } FILE_NAME_INFO
    len = p_buffer[0, 4].unpack1("L")
    name = p_buffer[4, len].encode(Encoding::UTF_8, Encoding::UTF_16LE, invalid: :replace)

    # Check if this could be a MSYS2 pty pipe ('\msys-XXXX-ptyN-XX')
    # or a cygwin pty pipe ('\cygwin-XXXX-ptyN-XX')
    name =~ /(msys-|cygwin-).*-pty/ ? true : false
  end

  def map_vk_to_char(vk)
    res = @MapVirtualKeyA.call(vk, 2) # MAPVK_VK_TO_CHAR, convert VK to char
  end

  def map_vk_to_codepoint(vk, sc, cks)
    # map vk to base char
    ks = "\0" * 256
    wchar = "\0" * 2
    ks[VK_SHIFT] = "\x80" if cks.anybits?(SHIFT_PRESSED)
    ks[VK_MENU] = "\x80" if cks.anybits?(ALT_PRESSED)
    ks[VK_CAPITAL] =  "\x01" if cks.anybits?(CAPSLOCK_ON)
    ks[VK_LSHIFT] = "\x80" if cks.anybits?(SHIFT_PRESSED)
    ks[VK_LMENU] = "\x80" if cks.anybits?(LEFT_ALT_PRESSED)
    ks[VK_RMENU] = "\x80" if cks.anybits?(RIGHT_ALT_PRESSED)
    ks[vk] = "\x80"
    res = @ToUnicode.call(vk, sc, ks, wchar, 1, 1)
    return wchar.unpack1("S") if res > 0
    return 0
  end

  CTRL_MAP = {
    "2".b => 0,
    "3".b => 27,
    "4".b => 28,
    "5".b => 29,
    "6".b => 30,
    "7".b => 31,
    "8".b => 127,
    "?".b => 127,
    "/".b => 31,
  }
  SEQ_MAP = {
    VK_UP		=> [ CSI, "" , "A" ],
    VK_DOWN		=> [ CSI, "" , "B" ],
    VK_RIGHT	=> [ CSI, "" , "C" ],
    VK_LEFT		=> [ CSI, "" , "D" ],
    VK_CLEAR	=> [ CSI, "" , "G" ],
    VK_HOME		=> [ CSI, "1", "~" ],
    VK_INSERT	=> [ CSI, "2", "~" ],
    VK_DELETE	=> [ CSI, "3", "~" ],
    VK_END		=> [ CSI, "4", "~" ],
    VK_PRIOR	=> [ CSI, "5", "~" ],
    VK_NEXT		=> [ CSI, "6", "~" ],
    VK_F1		=> [ SS3, "" , "P" ],
    VK_F2		=> [ SS3, "" , "Q" ],
    VK_F3		=> [ SS3, "" , "R" ],
    VK_F4		=> [ SS3, "" , "S" ],
    VK_F5		=> [ CSI, "15", "~" ],
    VK_F6		=> [ CSI, "17", "~" ],
    VK_F7		=> [ CSI, "18", "~" ],
    VK_F8		=> [ CSI, "19", "~" ],
    VK_F9		=> [ CSI, "20", "~" ],
    VK_F10		=> [ CSI, "21", "~" ],
    VK_F11		=> [ CSI, "23", "~" ],
    VK_F12		=> [ CSI, "24", "~" ],
  }
  MOD_MAP = ["", ";2", ";3", ";4", ";5", ";6", ";7", ";8"]
  NUMPAD_MAP = {
    VK_NUMPAD0 => [ VK_INSERT, 0x30 ],
    VK_NUMPAD1 => [ VK_END, 0x31 ],
    VK_NUMPAD2 => [ VK_DOWN, 0x32 ],
    VK_NUMPAD3 => [ VK_NEXT, 0x33 ],
    VK_NUMPAD4 => [ VK_LEFT, 0x34 ],
    VK_NUMPAD5 => [ VK_CLEAR, 0x35 ],
    VK_NUMPAD6 => [ VK_RIGHT, 0x36 ],
    VK_NUMPAD7 => [ VK_HOME, 0x37 ],
    VK_NUMPAD8 => [ VK_UP, 0x38 ],
    VK_NUMPAD9 => [ VK_PRIOR, 0x39 ],
    VK_DECIMAL => [ VK_DELETE, VK_DECIMAL ]
  }

  def process_key_event(repeat_count, virtual_key_code, virtual_scan_code, char_code, control_key_state, is_key_down)

    ctrl = control_key_state.anybits?(CTRL_PRESSED)
    alt = control_key_state.anybits?(ALT_PRESSED)
    shift = control_key_state.anybits?(SHIFT_PRESSED)
    seq = nil

    if !is_key_down
      return if virtual_key_code != VK_MENU
      return if char_code == 0
    end

    if char_code == 0 && virtual_scan_code < 54
      # full key with or without AltGr => dead key(?)
      return if ctrl && alt
      return if !ctrl && !alt
    end

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

    if is_key_down
      case char_code
      when 32	# space
        if ctrl
          alt, ctrl = true, false # ctrl+space is mapped to alt+space
        end
      when 9	# TAB
        seq = "\e[Z" if shift
      when 0
        if alt && !ctrl && !shift &&
            VK_NUMPAD0 <= virtual_key_code && virtual_key_code <= VK_NUMPAD9
          return
        end
        numpad = NUMPAD_MAP[virtual_key_code]
        if numpad
          numlk = control_key_state.allbits?(NUMLOCK_ON)
          numlk = shift = false if numlk && shift
          virtual_key_code = numpad[numlk ? 1 : 0]
        end
        seq = SEQ_MAP[virtual_key_code]
        if seq
          intro, lead, trail = *seq
        elsif virtual_key_code == VK_TAB
          seq = shift ? "\e[Z" : "\t"
        else
          # raw_key = map_vk_to_char(virtual_key_code)
          raw_key = map_vk_to_codepoint(virtual_key_code, virtual_scan_code, control_key_state)
          return if raw_key == 0
          char_code = CTRL_MAP[raw_key.chr(Encoding::BINARY)] || case raw_key
          when 64..127, 0x2f, 0x20
            raw_key & 0x1f
          else
            raw_key
          end
        end
      end
    end

    if intro
      if control_key_state.anybits?(SAC_MASK)
        modindex = (shift ? 1 : 0) + (alt ? 2 : 0) + (ctrl ? 4 : 0)
        if lead == ""
          intro = CSI
          lead = "1"
        end
        mod = MOD_MAP[modindex]
      end
      seq = [intro, lead, mod, trail].join('')
    else
      seq = (alt ? "\e" : "") + (seq || char_code.chr(Encoding::UTF_8))
    end

    @output_buf.concat(seq.bytes)
  end

  def check_input_event
    num_of_events = 0.chr * 8
    while @output_buf.empty?
      Reline.core.line_editor.handle_signal
      if @WaitForSingleObject.(@hConsoleInputHandle, 100) != 0 # max 0.1 sec
        # prevent for background consolemode change
        @legacy_console = getconsolemode & ENABLE_VIRTUAL_TERMINAL_PROCESSING == 0
        next
      end
      next if @GetNumberOfConsoleInputEvents.(@hConsoleInputHandle, num_of_events) == 0 or num_of_events.unpack1('L') == 0
      input_records = 0.chr * 20 * 80
      read_event = 0.chr * 4
      if @ReadConsoleInputW.(@hConsoleInputHandle, input_records, 80, read_event) != 0
        read_events = read_event.unpack1('L')
        0.upto(read_events) do |idx|
          input_record = input_records[idx * 20, 20]
          event = input_record[0, 2].unpack1('s*')
          case event
          when WINDOW_BUFFER_SIZE_EVENT
            @winch_handler.()
          when KEY_EVENT
            key_down = input_record[4, 4].unpack1('l*')
            repeat_count = input_record[8, 2].unpack1('s*')
            virtual_key_code = input_record[10, 2].unpack1('s*')
            virtual_scan_code = input_record[12, 2].unpack1('s*')
            char_code = input_record[14, 2].unpack1('S*')
            control_key_state = input_record[16, 2].unpack1('S*')
            is_key_down = key_down.zero? ? false : true
            process_key_event(repeat_count, virtual_key_code, virtual_scan_code, char_code, control_key_state, is_key_down)
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

  START_BRACKETED_PASTE = String.new("\e[200~", encoding: Encoding::ASCII_8BIT)
  END_BRACKETED_PASTE = String.new("\e[201~", encoding: Encoding::ASCII_8BIT)
  def read_bracketed_paste
    buffer = String.new(encoding: Encoding::ASCII_8BIT)
    until buffer.end_with?(END_BRACKETED_PASTE)
      c = getc(Float::INFINITY)
      break unless c
      buffer << c
    end
    string = buffer.delete_suffix(END_BRACKETED_PASTE).force_encoding(encoding)
    string.valid_encoding? ? string : ''
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
    if not @output_buf.empty?
      false
    elsif @kbhit.call == 0
      true
    else
      false
    end
  end

  def get_console_screen_buffer_info
    # CONSOLE_SCREEN_BUFFER_INFO
    # [ 0,2] dwSize.X
    # [ 2,2] dwSize.Y
    # [ 4,2] dwCursorPositions.X
    # [ 6,2] dwCursorPositions.Y
    # [ 8,2] wAttributes
    # [10,2] srWindow.Left
    # [12,2] srWindow.Top
    # [14,2] srWindow.Right
    # [16,2] srWindow.Bottom
    # [18,2] dwMaximumWindowSize.X
    # [20,2] dwMaximumWindowSize.Y
    csbi = 0.chr * 22
    if @GetConsoleScreenBufferInfo.call(@hConsoleHandle, csbi) != 0
      # returns [width, height, x, y, attributes, left, top, right, bottom]
      csbi.unpack("s9")
    else
      return nil
    end
  end

  ALTERNATIVE_CSBI = [80, 24, 0, 0, 7, 0, 0, 79, 23].freeze

  def get_screen_size
    width, _, _, _, _, _, top, _, bottom = get_console_screen_buffer_info || ALTERNATIVE_CSBI
    [bottom - top + 1, width]
  end

  def cursor_pos
    _, _, x, y, _, _, top, = get_console_screen_buffer_info || ALTERNATIVE_CSBI
    Reline::CursorPos.new(x, y - top)
  end

  def move_cursor_column(val)
    _, _, _, y, = get_console_screen_buffer_info
    @SetConsoleCursorPosition.call(@hConsoleHandle, y * 65536 + val) if y
  end

  def move_cursor_up(val)
    if val > 0
      _, _, x, y, _, _, top, = get_console_screen_buffer_info
      return unless y
      y = (y - top) - val
      y = 0 if y < 0
      @SetConsoleCursorPosition.call(@hConsoleHandle, (y + top) * 65536 + x)
    elsif val < 0
      move_cursor_down(-val)
    end
  end

  def move_cursor_down(val)
    if val > 0
      _, _, x, y, _, _, top, _, bottom = get_console_screen_buffer_info
      return unless y
      screen_height = bottom - top
      y = (y - top) + val
      y = screen_height if y > screen_height
      @SetConsoleCursorPosition.call(@hConsoleHandle, (y + top) * 65536 + x)
    elsif val < 0
      move_cursor_up(-val)
    end
  end

  def erase_after_cursor
    width, _, x, y, attributes, = get_console_screen_buffer_info
    return unless x
    written = 0.chr * 4
    @FillConsoleOutputCharacter.call(@hConsoleHandle, 0x20, width - x, y * 65536 + x, written)
    @FillConsoleOutputAttribute.call(@hConsoleHandle, attributes, width - x, y * 65536 + x, written)
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
      width, _, _, _, attributes, _, top, _, bottom = get_console_screen_buffer_info
      return unless width
      fill_length = width * (bottom - top + 1)
      screen_topleft = top * 65536
      written = 0.chr * 4
      @FillConsoleOutputCharacter.call(@hConsoleHandle, 0x20, fill_length, screen_topleft, written)
      @FillConsoleOutputAttribute.call(@hConsoleHandle, attributes, fill_length, screen_topleft, written)
      @SetConsoleCursorPosition.call(@hConsoleHandle, screen_topleft)
    else
      @output.write "\e[2J" "\e[H"
    end
  end

  def set_screen_size(rows, columns)
    raise NotImplementedError
  end

  def hide_cursor
    size = 100
    visible = 0 # 0 means false
    cursor_info = [size, visible].pack('Li')
    @SetConsoleCursorInfo.call(@hConsoleHandle, cursor_info)
  end

  def show_cursor
    size = 100
    visible = 1 # 1 means true
    cursor_info = [size, visible].pack('Li')
    @SetConsoleCursorInfo.call(@hConsoleHandle, cursor_info)
  end

  def set_winch_handler(&handler)
    @winch_handler = handler
  end

  def prep
    # Enable bracketed paste
    # @output.write "\e[?2004h" if Reline.core.config.enable_bracketed_paste && !win_legacy_console?
    nil
  end

  def deprep(otio)
    # Disable bracketed paste
    # @output.write "\e[?2004l" if Reline.core.config.enable_bracketed_paste && !win_legacy_console?
    nil
  end

  def disable_auto_linewrap(setting = true, &block)
    mode = getconsolemode
    if 0 == (mode & ENABLE_VIRTUAL_TERMINAL_PROCESSING)
      if block
        begin
          setconsolemode(mode & ~ENABLE_WRAP_AT_EOL_OUTPUT)
          block.call
        ensure
          setconsolemode(mode | ENABLE_WRAP_AT_EOL_OUTPUT)
        end
      else
        if setting
          setconsolemode(mode & ~ENABLE_WRAP_AT_EOL_OUTPUT)
        else
          setconsolemode(mode | ENABLE_WRAP_AT_EOL_OUTPUT)
        end
      end
    else
      block.call if block
    end
  end
end
