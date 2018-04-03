require 'reline'
require 'reline/key_actor'
require 'reline/kill_ring'
require 'reline/unicode'

class Reline::LineEditor
  attr_reader :line

  def initialize(key_actor, prompt)
    @prompt = prompt
    @prompt_width = calculate_width(@prompt)
    @cursor = 0
    @cursor_max = 0
    @byte_pointer = 0
    @line = String.new
    @key_actor = key_actor
    @finished = false
    @history_pointer = nil
    @line_backup_in_history
    @kill_ring = Reline::KillRing.new
    @multibyte_buffer = []
    @meta_prefix = false

    print prompt
  end

  def input_key(key)
    if !@multibyte_buffer.empty?
      @multibyte_buffer << key
      first_c = @multibyte_buffer.first
      byte_size = Reline::Unicode.get_mbchar_byte_size_by_first_char(first_c)
      if @multibyte_buffer.size >= byte_size
        edit_insert(@multibyte_buffer)
        @multibyte_buffer = []
        @kill_ring.process
      end
    elsif Reline::Unicode.get_mbchar_byte_size_by_first_char(key) > 1
      @multibyte_buffer << key
    elsif key == "\e".ord # meta key
      if @meta_prefix
        # escape twice
        @meta_prefix = false
        @kill_ring.process
      else
        @meta_prefix = true
      end
    else
      if @meta_prefix
        key |= 0b10000000 if key.nobits?(0b10000000)
        @meta_prefix = false
      end
      method_symbol = @key_actor.get_method(key)
      if method_symbol and respond_to?(method_symbol, true)
        __send__(method_symbol, key)
        @kill_ring.process
      end
    end
  end

  def finished?
    @finished
  end

  def finish
    @finished = true
  end

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

  private def calculate_width(str)
    str.grapheme_clusters.inject(0) { |width, gc| width + Reline::Unicode.get_mbchar_width(gc) }
  end

  private def edit_insert(key)
    if key.instance_of?(Array)
      mbchar = key.map(&:chr).join.force_encoding('UTF-8')
      width = Reline::Unicode.get_mbchar_width(mbchar)
      if @cursor == @cursor_max
        print mbchar
        @line += mbchar
      else
        @line = byteinsert(@line, @byte_pointer, mbchar)
        print @line.byteslice(@byte_pointer..-1)
        print "\e[#{@prompt_width + @cursor + width + 1}G"
      end
      @byte_pointer += Reline::Unicode.get_mbchar_byte_size_by_first_char(key.first)
      @cursor += width
      @cursor_max += width
    else
      if @cursor == @cursor_max
        print key.chr
        @line += key.chr
      else
        @line = byteinsert(@line, @byte_pointer, key.chr)
        print @line.byteslice(@byte_pointer..-1)
        print "\e[#{@prompt_width + @cursor + 2}G"
      end
      @byte_pointer += 1
      @cursor += 1
      @cursor_max += 1
    end
  end
  alias_method :edit_digit, :edit_insert

  private def edit_next_char(key)
    byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
    if @byte_pointer < @line.bytesize
      mbchar = @line.byteslice(@byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor += width if width
      @byte_pointer += byte_size
      print "\e[#{width}C"
    end
  end

  private def edit_prev_char(key)
    if @cursor > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      mbchar = @line.byteslice(@byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor -= width
      print "\e[#{width}D"
    end
  end

  private def edit_move_to_beg(key)
    @byte_pointer = 0
    @cursor = 0
    print "\e[#{@prompt_width + 1}G"
  end

  private def edit_move_to_end(key)
    last_mbchar_size = nil
    @byte_pointer = 0
    @cursor = 0
    byte_size = 0
    while @byte_pointer < @line.bytesize
      byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
      if byte_size > 0
        mbchar = @line.byteslice(@byte_pointer, byte_size)
        @cursor += Reline::Unicode.get_mbchar_width(mbchar)
      end
      @byte_pointer += byte_size
    end
    print "\e[#{@prompt_width + @cursor + 1}G"
  end

  private def edit_prev_history(key)
    if Reline::HISTORY.empty?
      return
    end
    if @history_pointer.nil?
      @history_pointer = Reline::HISTORY.size - 1
      @line_backup_in_history = @line
      @line = Reline::HISTORY[@history_pointer]
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      @cursor = @line.size
    elsif @history_pointer.zero?
      return
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer -= 1
      @line = Reline::HISTORY[@history_pointer]
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      @cursor = @line.size
    end
  end

  private def edit_next_history(key)
    if @history_pointer.nil?
      return
    elsif @history_pointer == (Reline::HISTORY.size - 1)
      @history_pointer = nil
      @line = @line_backup_in_history
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      @cursor = @line.size
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer += 1
      @line = Reline::HISTORY[@history_pointer]
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      @cursor = @line.size
    end
  end

  private def edit_newline(key)
    if @history_pointer
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer = nil
    end
    print "\r\n"
    @finished = true
    @line += "\n"
  end

  private def emacs_delete_prev_char(key)
    if @cursor > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor -= width
      @cursor_max -= width
      print "\e[#{@prompt_width + @cursor + 1}G"
      print "\e[0K"
      print @line.byteslice(@byte_pointer..-1) + ' '
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def edit_kill_line(key)
    if @line.bytesize > @byte_pointer
      @line, deleted = byteslice!(@line, @byte_pointer, @line.bytesize - @byte_pointer)
      @byte_pointer = @line.bytesize
      @cursor = @cursor_max = calculate_width(@line)
      @kill_ring.append(deleted)
      print "\e[0K"
    end
  end

  private def emacs_kill_line(key)
    if @byte_pointer > 0
      @line, deleted = byteslice!(@line, 0, @byte_pointer)
      @byte_pointer = 0
      @kill_ring.append(deleted, true)
      @cursor_max = calculate_width(@line)
      @cursor = 0
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt_width + 1}G"
    end
  end

  private def emacs_delete_or_list(key)
    if @line.size == 0
      @line = nil
      finish
    elsif @line.size > 0 and @byte_pointer < @line.size
      splitted_last = @line.byteslice(@byte_pointer, @line.size)
      mbchar = splitted_last.grapheme_clusters.first
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor_max -= width
      @line, deleted = byteslice!(@line, @byte_pointer, mbchar.bytesize)
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def emacs_yank(key)
    yanked = @kill_ring.yank
    if yanked
      @line = byteinsert(@line, @byte_pointer, yanked)
      print @line.byteslice(@byte_pointer..-1)
      yanked_width = calculate_width(yanked)
      @cursor += yanked_width
      @cursor_max += yanked_width
      @byte_pointer += yanked.bytesize
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def emacs_yank_pop(key)
    yanked, prev_yank = @kill_ring.yank_pop
    if yanked
      prev_yank_width = calculate_width(prev_yank)
      @cursor -= prev_yank_width
      @cursor_max -= prev_yank_width
      @byte_pointer -= prev_yank.bytesize
      @line, mbchar = byteslice!(@line, @byte_pointer, prev_yank.bytesize)
      @line = byteinsert(@line, @byte_pointer, yanked)
      yanked_width = calculate_width(yanked)
      @cursor += yanked_width
      @cursor_max += yanked_width
      @byte_pointer += yanked.bytesize
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def edit_clear_screen(key)
    print "\e[2J"
    print "\e[1;1H"
    print @prompt
    print @line
    print "\e[#{@prompt_width + @cursor + 1}G"
  end

  private def emacs_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
      print "\e[#{width}C"
    end
  end

  private def edit_prev_word(key)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @cursor -= width
      print "\e[#{width}D"
    end
  end

  private def emacs_delete_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.forward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer, byte_size)
      @kill_ring.append(word)
      @cursor_max -= width
      print "\e[#{@prompt_width + @cursor + 1}G"
      print @line.byteslice(@byte_pointer..-1)
      print ' ' * width
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def edit_delete_prev_word(key)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.backward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer - byte_size, byte_size)
      @kill_ring.append(word, true)
      @byte_pointer -= byte_size
      @cursor -= width
      @cursor_max -= width
      print "\e[#{@prompt_width + @cursor + 1}G"
      print @line.byteslice(@byte_pointer..-1)
      print ' ' * width
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def edit_transpose_chars(key)
    if @byte_pointer > 0
      if @cursor_max > @cursor
        byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
        mbchar = @line.byteslice(@byte_pointer, byte_size)
        width = Reline::Unicode.get_mbchar_width(mbchar)
        @cursor += width
        @byte_pointer += byte_size
      end
      back1_byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      if (@byte_pointer - back1_byte_size) > 0
        back2_byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer - back1_byte_size)
        back2_pointer = @byte_pointer - back1_byte_size - back2_byte_size
        @line, back2_mbchar = byteslice!(@line, back2_pointer, back2_byte_size)
        @line = byteinsert(@line, @byte_pointer - back2_byte_size, back2_mbchar)
        print "\e[2K"
        print "\e[1G"
        print @prompt
        print @line
        print "\e[#{@prompt_width + @cursor + 1}G"
      end
    end
  end

  private def emacs_capitol_case(key)
    if @line.bytesize > @byte_pointer
      byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
      cursor_mbchar = @line.byteslice(@byte_pointer, byte_size)
      byte_size, width = Reline::Unicode.forward_word(@line, @byte_pointer)
      if cursor_mbchar =~ /^[a-z]/
        @line = @line.byteslice(0, @byte_pointer) + cursor_mbchar.upcase + @line.byteslice((@byte_pointer + 1)..-1)
        print cursor_mbchar.upcase
      end
      @byte_pointer += byte_size
      @cursor += width
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def emacs_lower_case(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.forward_word(@line, @byte_pointer)
      part = @line.byteslice(@byte_pointer, byte_size).grapheme_clusters.map { |mbchar|
        mbchar =~ /[A-Z]/ ? mbchar.downcase : mbchar
      }.join
      rest = @line.byteslice((@byte_pointer + byte_size)..-1)
      @line = @line.byteslice(0, @byte_pointer) + part
      @byte_pointer = @line.bytesize
      @cursor = calculate_width(@line)
      @cursor_max = @cursor + calculate_width(rest)
      @line += rest
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end

  private def emacs_upper_case(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.forward_word(@line, @byte_pointer)
      part = @line.byteslice(@byte_pointer, byte_size).grapheme_clusters.map { |mbchar|
        mbchar =~ /[a-z]/ ? mbchar.upcase : mbchar
      }.join
      rest = @line.byteslice((@byte_pointer + byte_size)..-1)
      @line = @line.byteslice(0, @byte_pointer) + part
      @byte_pointer = @line.bytesize
      @cursor = calculate_width(@line)
      @cursor_max = @cursor + calculate_width(rest)
      @line += rest
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt_width + @cursor + 1}G"
    end
  end
end
