class Reline::KeyStroke
  ESC_BYTE = 27
  CSI_PARAMETER_BYTES_RANGE = 0x30..0x3f
  CSI_INTERMEDIATE_BYTES_RANGE = (0x20..0x2f)

  def initialize(config, encoding)
    @config = config
    @encoding = encoding
  end

  def match_status(input)
    matched = key_mapping.get(input)
    if key_mapping.matching?(input)
      matched ? :matching_matched : :matching
    elsif matched
      :matched
    elsif input[0] == ESC_BYTE
      match_unknown_escape_sequence(input, vi_mode: @config.editing_mode_is?(:vi_insert, :vi_command))
    else
      s = input.map(&:chr).join.force_encoding(@encoding)
      if s.valid_encoding?
        s.size == 1 ? :matched : :unmatched
      else
        # invalid byte sequence can be matching (part of multi-byte character) or matched (broken input to be ignored)
        :matching_matched
      end
    end
  end

  def valid_char_bytes?(bytes)
    bytes.map(&:chr).join.force_encoding(@encoding)
  end

  def expand(input)
    matched_bytes = []
    (1..input.size).each do |i|
      bytes = input.take(i)
      case match_status(bytes)
      when :matched
        matched_bytes = bytes
        break
      when :matching_matched
        matched_bytes = bytes
      end
    end

    func = key_mapping.get(matched_bytes)
    return [func, matched_bytes, input.drop(matched_bytes.size)] if func || matched_bytes[0] == ESC_BYTE

    s = input.map(&:chr).join.force_encoding(@encoding)
    s = nil unless s.valid_encoding?
    [s, input, []]
  end

  private

  # returns match status of CSI/SS3 sequence
  def match_unknown_escape_sequence(input, vi_mode: false)
    idx = 0
    return :unmatched unless input[idx] == ESC_BYTE
    idx += 1
    idx += 1 if input[idx] == ESC_BYTE

    case input[idx]
    when nil
      return :matching
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
      return :unmatched if vi_mode
    end
    input[idx + 1] ? :unmatched : input[idx] ? :matched : :matching
  end

  def key_mapping
    @config.key_bindings
  end
end
