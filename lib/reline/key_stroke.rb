class Reline::KeyStroke
  ESC_BYTE = 27
  CSI_PARAMETER_BYTES_RANGE = 0x30..0x3f
  CSI_INTERMEDIATE_BYTES_RANGE = (0x20..0x2f)
  KITTY_MODIFIER_SHIFT = 0b001
  KITTY_MODIFIER_ALT = 0b010
  KITTY_MODIFIER_CTRL = 0b100

  attr_accessor :encoding

  def initialize(config, encoding)
    @config = config
    @encoding = encoding
  end

  # Input exactly matches to a key sequence
  MATCHING = :matching
  # Input partially matches to a key sequence
  MATCHED = :matched
  # Input matches to a key sequence and the key sequence is a prefix of another key sequence
  MATCHING_MATCHED = :matching_matched
  # Input does not match to any key sequence
  UNMATCHED = :unmatched

  def match_status(input)
    matching = key_mapping.matching?(input)
    matched = key_mapping.get(input)
    if matching && matched
      MATCHING_MATCHED
    elsif matching
      MATCHING
    elsif matched
      MATCHED
    elsif input[0] == ESC_BYTE
      match_unknown_escape_sequence(input, vi_mode: @config.editing_mode_is?(:vi_insert, :vi_command))
    else
      s = input.pack('c*').force_encoding(@encoding)
      if s.valid_encoding?
        s.size == 1 ? MATCHED : UNMATCHED
      else
        # Invalid string is MATCHING (part of valid string) or MATCHED (invalid bytes to be ignored)
        MATCHING_MATCHED
      end
    end
  end

  def expand(input)
    matched_bytes = nil
    (1..input.size).each do |i|
      bytes = input.take(i)
      status = match_status(bytes)
      matched_bytes = bytes if status == MATCHED || status == MATCHING_MATCHED
      break if status == MATCHED || status == UNMATCHED
    end
    return [[], []] unless matched_bytes

    func = key_mapping.get(matched_bytes)
    s = matched_bytes.pack('c*').force_encoding(@encoding)
    if func.is_a?(Array)
      # Perform simple macro expansion for single byte key bindings.
      # Multibyte key bindings and recursive macro expansion are not supported yet.
      macro = func.pack('c*').force_encoding(@encoding)
      keys = macro.chars.map do |c|
        f = key_mapping.get(c.bytes)
        Reline::Key.new(c, f.is_a?(Symbol) ? f : :ed_insert, false)
      end
    elsif func
      keys = [Reline::Key.new(s, func, false)]
    elsif (kitty_keys = expand_kitty_csi_u(matched_bytes))
      keys = kitty_keys
    else
      if s.valid_encoding? && s.size == 1
        keys = [Reline::Key.new(s, :ed_insert, false)]
      else
        keys = []
      end
    end

    [keys, input.drop(matched_bytes.size)]
  end

  private

  def expand_kitty_csi_u(bytes)
    packed = bytes.pack('C*')
    match = packed.match(/\A\e\[(?<codepoint>\d+)(?:;(?<modifiers>\d+))?u\z/)
    return unless match

    codepoint = Integer(match[:codepoint], 10)
    modifiers = Integer(match[:modifiers] || '1', 10)
    return unless codepoint.positive? && modifiers.positive?

    modifier_bits = modifiers - 1
    ctrl = (modifier_bits & KITTY_MODIFIER_CTRL) != 0
    alt = (modifier_bits & KITTY_MODIFIER_ALT) != 0

    normalized_bytes = []
    normalized_bytes << ESC_BYTE if alt

    if ctrl && (control_byte = control_byte_from_codepoint(codepoint))
      if control_byte == 3
        return [Reline::Key.new(String.new(encoding: @encoding), :ed_interrupt, false)]
      end
      normalized_bytes << control_byte
    elsif (special_bytes = special_bytes_from_codepoint(codepoint))
      normalized_bytes.concat(special_bytes)
    elsif (char = char_from_codepoint(codepoint))
      normalized_bytes.concat(char.bytes)
    else
      return
    end

    build_keys_from_bytes(normalized_bytes)
  end

  def build_keys_from_bytes(bytes)
    func = key_mapping.get(bytes)
    string = bytes.pack('C*').force_encoding(@encoding)
    if func
      [Reline::Key.new(string, func, false)]
    elsif string.valid_encoding? && string.size == 1
      [Reline::Key.new(string, :ed_insert, false)]
    elsif bytes.first == ESC_BYTE && bytes.size > 1
      expanded = bytes.each_with_index.filter_map do |byte, index|
        partial = bytes.take(index + 1)
        next if index.zero? && key_mapping.matching?(partial)

        char = [byte].pack('C').force_encoding(@encoding)
        func = key_mapping.get([byte])
        Reline::Key.new(char, func.is_a?(Symbol) ? func : :ed_insert, false)
      end
      expanded unless expanded.empty?
    end
  end

  def special_bytes_from_codepoint(codepoint)
    case codepoint
    when 8
      [8]
    when 9
      [9]
    when 13
      [13]
    when 27
      [27]
    when 127
      [127]
    end
  end

  def char_from_codepoint(codepoint)
    return unless codepoint <= 0x10ffff

    char = [codepoint].pack('U')
    char.valid_encoding? ? char : nil
  rescue RangeError
    nil
  end

  def control_byte_from_codepoint(codepoint)
    case codepoint
    when 63
      127
    when 64..95, 97..122
      codepoint & 0x1f
    end
  end

  # returns match status of CSI/SS3 sequence and matched length
  def match_unknown_escape_sequence(input, vi_mode: false)
    idx = 0
    return UNMATCHED unless input[idx] == ESC_BYTE
    idx += 1
    idx += 1 if input[idx] == ESC_BYTE

    case input[idx]
    when nil
      if idx == 1 # `ESC`
        return MATCHING_MATCHED
      else # `ESC ESC`
        return MATCHING
      end
    when 91 # == '['.ord
      # CSI sequence `ESC [ ... char`
      idx += 1
      idx += 1 while idx < input.size && CSI_PARAMETER_BYTES_RANGE.cover?(input[idx])
      idx += 1 while idx < input.size && CSI_INTERMEDIATE_BYTES_RANGE.cover?(input[idx])
    when 79 # == 'O'.ord
      # SS3 sequence `ESC O char`
      idx += 1
    else
      # `ESC char` or `ESC ESC char`
      return UNMATCHED if vi_mode
    end

    case input.size
    when idx
      MATCHING
    when idx + 1
      MATCHED
    else
      UNMATCHED
    end
  end

  def key_mapping
    @config.key_bindings
  end
end
