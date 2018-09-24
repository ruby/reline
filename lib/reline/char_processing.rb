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

  private def prev_byte_size
    if @line.bytesize == 0 or @byte_pointer == 0
      0
    else
      @line.byteslice(0..(@byte_pointer - 1)).grapheme_clusters.last.bytesize
    end
  end

  private def next_byte_size
    if @line.bytesize == 0 or @line.bytesize == @byte_pointer
      0
    else
      @line.byteslice(@byte_pointer..-1).grapheme_clusters.first.bytesize
    end
  end
end
