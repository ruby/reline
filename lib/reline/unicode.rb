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
end

require 'reline/unicode/east_asian_width'
