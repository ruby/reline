# Split off char processing methods from LineEditor
module CharProcessing
  private def byteslice!(str, byte_pointer, size)
    new_str = str.byteslice(0, byte_pointer)
    new_str << str.byteslice(byte_pointer + size, str.bytesize)
    [new_str, str.byteslice(byte_pointer, size)]
  end

  private def byteinsert(str, byte_pointer, other)
    new_str = str.byteslice(0, byte_pointer)
    new_str << other
    new_str << str.byteslice(byte_pointer, str.bytesize)
    new_str
  end

  private def prev_byte_size(offset = 0)
    byte_pointer = @byte_pointer + offset
    if @line.bytesize == 0 or byte_pointer == 0
      0
    else
      @line.byteslice(0..(byte_pointer - 1)).grapheme_clusters.last.bytesize
    end
  end

  private def next_byte_size(offset = 0)
    byte_pointer = @byte_pointer + offset
    if @line.bytesize == 0 or @line.bytesize == byte_pointer
      0
    else
      @line.byteslice(byte_pointer..-1).grapheme_clusters.first.bytesize
    end
  end

  private def em_backward_word
    byte_size = 0
    while 0 < (@byte_pointer - byte_size)
      size = prev_byte_size(-byte_size)
      mbchar = @line.byteslice(@byte_pointer - byte_size - size, size)
      break if mbchar =~ /\p{Word}/
      byte_size += size
    end
    while 0 < (@byte_pointer - byte_size)
      size = prev_byte_size(-byte_size)
      mbchar = @line.byteslice(@byte_pointer - byte_size - size, size)
      break if mbchar =~ /\P{Word}/
      byte_size += size
    end
    byte_size
  end

  private def em_forward_word
    byte_size = 0
    while @line.bytesize > (@byte_pointer + byte_size)
      size = next_byte_size(byte_size)
      mbchar = @line.byteslice(@byte_pointer + byte_size, size)
      break if mbchar =~ /\p{Word}/
      byte_size += size
    end
    while line.bytesize > (@byte_pointer + byte_size)
      size = next_byte_size(byte_size)
      mbchar = @line.byteslice(@byte_pointer + byte_size, size)
      break if mbchar =~ /\P{Word}/
      byte_size += size
    end
    byte_size
  end

  private def em_forward_word_with_capitalization
    byte_size = 0
    new_str = String.new
    while @line.bytesize > (@byte_pointer + byte_size)
      size = next_byte_size(byte_size)
      mbchar = @line.byteslice(@byte_pointer + byte_size, size)
      break if mbchar =~ /\p{Word}/
      new_str += mbchar
      byte_size += size
    end
    first = true
    while @line.bytesize > (@byte_pointer + byte_size)
      size = next_byte_size(byte_size)
      mbchar = @line.byteslice(@byte_pointer + byte_size, size)
      break if mbchar =~ /\P{Word}/
      if first
        new_str += mbchar.upcase
        first = false
      else
        new_str += mbchar.downcase
      end
      byte_size += size
    end
    [byte_size, new_str]
  end
end
