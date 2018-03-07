require 'reline'
require 'reline/key_actor'

class Reline::LineEditor
  attr_reader :line

  def initialize(key_actor, prompt)
    @prompt = prompt
    @cursor = 0
    @line = String.new
    @key_actor = key_actor
    @finished = false
    @history_pointer = nil
    @line_backup_in_history

    print prompt
  end

  def input_key(key)
    method_symbol = @key_actor.get_method(key)
    __send__(method_symbol, key) if method_symbol and respond_to?(method_symbol, true)
  end

  def finished?
    @finished
  end

  def finish
    @finished = true
  end

  private def edit_insert(key)
    if @cursor == @line.size
      print key.chr
      @line += key.chr
      @cursor += 1
    else
      @line.insert(@cursor, key.chr)
      print @line.slice(@cursor..-1)
      @cursor += 1
      print "\e[#{@prompt.size + @cursor + 1}G"
    end
  end
  alias_method :edit_digit, :edit_insert

  private def edit_next_char(key)
    if @cursor < @line.size
      @cursor += 1
      print "\e[1C"
    end
  end

  private def edit_prev_char(key)
    if @cursor > 0
      @cursor -= 1
      print "\e[1D"
    end
  end

  private def edit_move_to_beg(key)
    @cursor = 0
    print "\e[#{@prompt.size + 1}G"
  end

  private def edit_move_to_end(key)
    @cursor = @line.size
    print "\e[#{@prompt.size + @line.size + 1}G"
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
      @line.slice!(@cursor - 1)
      @cursor -= 1
      print "\e[#{@prompt.size + @cursor + 1}G"
      print @line.slice(@cursor..-1) + ' '
      print "\e[#{@prompt.size + @cursor + 1}G"
    end
  end

  private def edit_kill_line(key)
    if @cursor > 1
      @line.slice!(@cursor..@line.length)
      print "\e[0K"
    end
  end

  private def emacs_kill_line(key)
    if @cursor > 1
      @line.slice!(0..(@cursor - 1))
      @cursor = 0
      print "\e[2K"
      print "\e[1G"
      print @prompt
      print @line
      print "\e[#{@prompt.size + 1}G"
    end
  end

  private def emacs_delete_or_list(key)
    if @line.size == 0
      @line = nil
      finish
    elsif @line.size > 0 and @cursor < @line.size
      @line.slice!(@cursor)
      print @line.slice(@cursor..-1) + ' '
      print "\e[#{@prompt.size + @cursor + 1}G"
    end
  end
end
