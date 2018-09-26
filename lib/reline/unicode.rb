class Reline::Unicode
  def self.get_mbchar_byte_size_by_first_char(c)
    # Checks UTF-8 character byte size
    case c.ord
    # 0b0xxxxxxx
    when ->(code) { (code ^ 0b10000000).allbits?(0b10000000) } then 1
    # 0b110xxxxx
    when ->(code) { (code ^ 0b00100000).allbits?(0b11100000) } then 2
    # 0b1110xxxx
    when ->(code) { (code ^ 0b00010000).allbits?(0b11110000) } then 3
    # 0b11110xxx
    when ->(code) { (code ^ 0b00001000).allbits?(0b11111000) } then 4
    # 0b111110xx
    when ->(code) { (code ^ 0b00000100).allbits?(0b11111100) } then 5
    # 0b1111110x
    when ->(code) { (code ^ 0b00000010).allbits?(0b11111110) } then 6
    # successor of mbchar
    else 0
    end
  end

  def self.get_next_mbchar_size(line, byte_pointer)
    grapheme = line.byteslice(byte_pointer..-1).grapheme_clusters.first
    grapheme ? grapheme.bytesize : 0
  end

  def self.get_prev_mbchar_size(line, byte_pointer)
    if byte_pointer.zero?
      0
    else
      grapheme = line.byteslice(0..(byte_pointer - 1)).grapheme_clusters.last
      grapheme ? grapheme.bytesize : 0
    end
  end

  def self.em_forward_word_with_capitalization(line, byte_pointer)
    width = 0
    byte_size = 0
    new_str = String.new
    while line.bytesize > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\p{Word}/
      new_str += mbchar
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    first = true
    while line.bytesize > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\P{Word}/
      if first
        new_str += mbchar.upcase
        first = false
      else
        new_str += mbchar.downcase
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width, new_str]
  end

  def self.em_backward_word(line, byte_pointer)
    width = 0
    byte_size = 0
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      break if mbchar =~ /\p{Word}/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      break if mbchar =~ /\P{Word}/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width]
  end

  def self.vi_big_forward_word(line, byte_pointer)
    width = 0
    byte_size = 0
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\s/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\S/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width]
  end

  def self.vi_big_forward_end_word(line, byte_pointer)
    if (line.bytesize - 1) > byte_pointer
      size = get_next_mbchar_size(line, byte_pointer)
      mbchar = line.byteslice(byte_pointer, size)
      width = get_mbchar_width(mbchar)
      byte_size = size
    else
      return [0, 0]
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\S/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    prev_width = width
    prev_byte_size = byte_size
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\s/
      prev_width = width
      prev_byte_size = byte_size
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [prev_byte_size, prev_width]
  end

  def self.vi_big_backward_word(line, byte_pointer)
    width = 0
    byte_size = 0
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      break if mbchar =~ /\S/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      break if mbchar =~ /\s/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width]
  end

  def self.vi_forward_word(line, byte_pointer)
    if (line.bytesize - 1) > byte_pointer
      size = get_next_mbchar_size(line, byte_pointer)
      mbchar = line.byteslice(byte_pointer, size)
      if mbchar =~ /\w/
        started_by = :word
      elsif mbchar =~ /\s/
        started_by = :space
      else
        started_by = :non_word_printable
      end
      width = get_mbchar_width(mbchar)
      byte_size = size
    else
      return [0, 0]
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      case started_by
      when :word
        break if mbchar =~ /\W/
      when :space
        break if mbchar =~ /\S/
      when :non_word_printable
        break if mbchar =~ /\w|\s/
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      break if mbchar =~ /\S/
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width]
  end

  def self.vi_forward_end_word(line, byte_pointer)
    if (line.bytesize - 1) > byte_pointer
      size = get_next_mbchar_size(line, byte_pointer)
      mbchar = line.byteslice(byte_pointer, size)
      if mbchar =~ /\w/
        started_by = :word
      elsif mbchar =~ /\s/
        started_by = :space
      else
        started_by = :non_word_printable
      end
      width = get_mbchar_width(mbchar)
      byte_size = size
    else
      return [0, 0]
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      case started_by
      when :word
        break if mbchar =~ /\W/
      when :space
        break if mbchar =~ /\S/
      when :non_word_printable
        break if mbchar =~ /\w|\s/
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      if mbchar =~ /\S/
        if mbchar =~ /\w/
          started_by = :word
        else
          started_by = :non_word_printable
        end
        break
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    prev_width = width
    prev_byte_size = byte_size
    while (line.bytesize - 1) > (byte_pointer + byte_size)
      size = get_next_mbchar_size(line, byte_pointer + byte_size)
      mbchar = line.byteslice(byte_pointer + byte_size, size)
      case started_by
      when :word
        break if mbchar =~ /\W/
      when :non_word_printable
        break if mbchar =~ /[\w\s]/
      end
      prev_width = width
      prev_byte_size = byte_size
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [prev_byte_size, prev_width]
  end

  def self.vi_backward_word(line, byte_pointer)
    width = 0
    byte_size = 0
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      if mbchar =~ /\S/
        if mbchar =~ /\w/
          started_by = :word
        else
          started_by = :non_word_printable
        end
        break
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    while 0 < (byte_pointer - byte_size)
      size = get_prev_mbchar_size(line, byte_pointer - byte_size)
      mbchar = line.byteslice(byte_pointer - byte_size - size, size)
      case started_by
      when :word
        break if mbchar =~ /\W/
      when :non_word_printable
        break if mbchar =~ /[\w\s]/
      end
      width += get_mbchar_width(mbchar)
      byte_size += size
    end
    [byte_size, width]
  end
end

require 'reline/unicode/east_asian_width'
