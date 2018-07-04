require 'reline/kill_ring'
require 'reline/unicode'

require 'tempfile'
require 'pathname'

class Reline::LineEditor
  attr_reader :line
  attr_accessor :completion_proc
  attr_writer :retrieve_completion_block

  ARGUMENTABLE = %i{
    ed_delete_next_char
    ed_delete_prev_char#
    ed_delete_prev_word
    ed_next_char
    ed_next_history
    ed_next_line#
    ed_prev_char
    ed_prev_history
    ed_prev_line#
    ed_prev_word
    vi_to_column
    vi_next_word
    vi_prev_word
    vi_end_word
    vi_next_big_word
    vi_prev_big_word
    vi_end_big_word
    vi_next_char
  }

  module CompletionState
    NORMAL = :normal
    COMPLETION = :completion
    MENU = :menu
    JOURNEY = :journey
  end

  CompletionJourneyData = Struct.new('CompletionJourneyData', :preposing, :postposing, :list, :pointer)

  def initialize(key_actor, prompt)
    @prompt = prompt
    @prompt_width = calculate_width(@prompt)
    @cursor = 0
    @cursor_max = 0
    @byte_pointer = 0
    @line = String.new(encoding: 'UTF-8')
    @key_actor = key_actor
    @finished = false
    @cleared = false
    @history_pointer = nil
    @line_backup_in_history = nil
    @kill_ring = Reline::KillRing.new
    @vi_arg = nil
    @multibyte_buffer = []
    @meta_prefix = false
    @waiting_proc = nil
    @completion_journey_data = nil
    @completion_state = CompletionState::NORMAL
  end

  def rerender
    if @vi_arg
      prompt = "(arg: #{@vi_arg}) "
      prompt_width = calculate_width(prompt)
    else
      prompt = @prompt
      prompt_width = @prompt_width
    end
    if @cleared
      print "\e[2J"
      print "\e[1;1H"
      @cleared = false
    end
    print "\e[2K"
    print "\e[1G"
    print prompt
    print @line
    print "\e[#{prompt_width + @cursor + 1}G" unless @line.end_with?("\n")
  end

  def menu(target, list)
    puts
    list.each do |item|
      puts item
    end
  end

  def complete_internal_proc(list, is_menu)
    preposing, target, postposing = @retrieve_completion_block.(@line, @byte_pointer)
    list = list.select { |i| i.start_with?(target) }
    if is_menu
      menu(target, list)
      return nil
    end
    completed = list.inject { |memo, item|
      memo_mbchars = memo.unicode_normalize.grapheme_clusters
      item_mbchars = item.unicode_normalize.grapheme_clusters
      size = [memo_mbchars.size, item_mbchars.size].min
      result = ''
      size.times do |i|
        if memo_mbchars[i] == item_mbchars[i]
          result << memo_mbchars[i]
        else
          break
        end
      end
      result
    }
    [target, preposing, completed, postposing]
  end

  def complete(list)
    case @completion_state
    when CompletionState::NORMAL, CompletionState::JOURNEY
      @completion_state = CompletionState::COMPLETION
    end
    is_menu = (@completion_state == CompletionState::MENU)
    result = complete_internal_proc(list, is_menu)
    return if result.nil?
    target, preposing, completed, postposing = result
    if target <= completed and @completion_state == CompletionState::COMPLETION
      @completion_state = CompletionState::MENU
      if target < completed
        @line = preposing + completed + postposing
        line_to_pointer = preposing + completed
        @cursor_max = calculate_width(@line)
        @cursor = calculate_width(line_to_pointer)
        @byte_pointer = line_to_pointer.bytesize
      end
    end
  end

  def move_completed_list(list, direction)
    case @completion_state
    when CompletionState::NORMAL, CompletionState::COMPLETION, CompletionState::MENU
      @completion_state = CompletionState::JOURNEY
      result = @retrieve_completion_block.(@line, @byte_pointer)
      return if result.nil?
      preposing, target, postposing = result
      @completion_journey_data = CompletionJourneyData.new(
        preposing, postposing,
        [target] + list.select{ |item| item.start_with?(target) }, 0)
      @completion_state = CompletionState::JOURNEY
    else
      case direction
      when :up
        @completion_journey_data.pointer -= 1
        if @completion_journey_data.pointer < 0
          @completion_journey_data.pointer = @completion_journey_data.list.size - 1
        end
      when :down
        @completion_journey_data.pointer += 1
        if @completion_journey_data.pointer >= @completion_journey_data.list.size
          @completion_journey_data.pointer = 0
        end
      end
      completed = @completion_journey_data.list[@completion_journey_data.pointer]
      @line = @completion_journey_data.preposing + completed + @completion_journey_data.postposing
      line_to_pointer = @completion_journey_data.preposing + completed
      @cursor_max = calculate_width(@line)
      @cursor = calculate_width(line_to_pointer)
      @byte_pointer = line_to_pointer.bytesize
    end
  end

  def input_key(key)
    completion_occurs = false
    if !@multibyte_buffer.empty?
      @multibyte_buffer << key
      first_c = @multibyte_buffer.first
      byte_size = Reline::Unicode.get_mbchar_byte_size_by_first_char(first_c)
      if @multibyte_buffer.size >= byte_size
        if @waiting_proc
          @waiting_proc.(@multibyte_buffer)
        else
          ed_insert(@multibyte_buffer)
        end
        @multibyte_buffer = []
        @kill_ring.process
      end
    elsif Reline::Unicode.get_mbchar_byte_size_by_first_char(key) > 1
      @multibyte_buffer << key
    elsif [Reline::KeyActor::Emacs, Reline::KeyActor::ViInsert].include?(@key_actor) and key == "\C-i".ord
      result = @completion_proc&.(@line)
      if result.is_a?(Array)
        completion_occurs = true
        complete(result)
      end
    elsif Reline::KeyActor::ViInsert == @key_actor and ["\C-p".ord, "\C-n".ord].include?(key)
      result = @completion_proc&.(@line)
      if result.is_a?(Array)
        completion_occurs = true
        move_completed_list(result, "\C-p".ord == key ? :up : :down)
      end
    elsif Reline::KeyActor::Emacs == @key_actor and key == "\e".ord # meta key
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
        if @vi_arg
          if key.chr =~ /[0-9]/
            ed_argument_digit(key)
          else
            if ARGUMENTABLE.include?(method_symbol)
              __send__(method_symbol, key, @vi_arg)
            elsif @waiting_proc
              @waiting_proc.(key)
            else
              __send__(method_symbol, key)
            end
            @kill_ring.process
            @vi_arg = nil
          end
        elsif @waiting_proc
          @waiting_proc.(key)
          @kill_ring.process
        else
          __send__(method_symbol, key)
          @kill_ring.process
        end
      end
    end
    unless completion_occurs
      case @completion_state
      when CompletionState::COMPLETION, CompletionState::MENU
        @completion_state = CompletionState::NORMAL
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

  private def ed_insert(key)
    if key.instance_of?(Array)
      mbchar = key.map(&:chr).join.force_encoding('UTF-8')
      width = Reline::Unicode.get_mbchar_width(mbchar)
      if @cursor == @cursor_max
        @line += mbchar
      else
        @line = byteinsert(@line, @byte_pointer, mbchar)
      end
      @byte_pointer += Reline::Unicode.get_mbchar_byte_size_by_first_char(key.first)
      @cursor += width
      @cursor_max += width
    else
      if @cursor == @cursor_max
        @line += key.chr
      else
        @line = byteinsert(@line, @byte_pointer, key.chr)
      end
      @byte_pointer += 1
      @cursor += 1
      @cursor_max += 1
    end
  end
  alias_method :ed_digit, :ed_insert

  private def ed_next_char(key, arg = 1)
    byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
    if Reline::KeyActor::ViCommand == @key_actor
      ignite = ((@byte_pointer + byte_size) < @line.bytesize)
    else
      ignite = (@byte_pointer < @line.bytesize)
    end
    if ignite
      mbchar = @line.byteslice(@byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor += width if width
      @byte_pointer += byte_size
    end
    arg -= 1
    ed_next_char(key, arg) if arg > 0
  end

  private def ed_prev_char(key, arg = 1)
    if @cursor > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      mbchar = @line.byteslice(@byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor -= width
    end
    arg -= 1
    ed_prev_char(key, arg) if arg > 0
  end

  private def ed_move_to_beg(key)
    @byte_pointer = 0
    @cursor = 0
  end

  private def ed_move_to_end(key)
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
    if Reline::KeyActor::ViCommand == @key_actor
      ed_prev_char(key)
    end
  end

  private def ed_prev_history(key, arg = 1)
    if Reline::HISTORY.empty?
      return
    end
    if @history_pointer.nil?
      @history_pointer = Reline::HISTORY.size - 1
      @line_backup_in_history = @line
      @line = Reline::HISTORY[@history_pointer]
      @cursor_max = @cursor = calculate_width(@line)
      @byte_pointer = @line.bytesize
    elsif @history_pointer.zero?
      return
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer -= 1
      @line = Reline::HISTORY[@history_pointer]
      @cursor_max = @cursor = calculate_width(@line)
      @byte_pointer = @line.bytesize
    end
    arg -= 1
    ed_prev_history(key, arg) if arg > 0
  end

  private def ed_next_history(key, arg = 1)
    if @history_pointer.nil?
      return
    elsif @history_pointer == (Reline::HISTORY.size - 1)
      @history_pointer = nil
      @line = @line_backup_in_history
      @cursor_max = @cursor = calculate_width(@line)
      @byte_pointer = @line.bytesize
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer += 1
      @line = Reline::HISTORY[@history_pointer]
      @cursor_max = @cursor = calculate_width(@line)
      @byte_pointer = @line.bytesize
    end
    arg -= 1
    ed_next_history(key, arg) if arg > 0
  end

  private def ed_newline(key)
    if @history_pointer
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer = nil
    end
    finish
    @line += "\n"
  end

  private def em_delete_prev_char(key)
    if @cursor > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor -= width
      @cursor_max -= width
    end
  end

  private def ed_kill_line(key)
    if @line.bytesize > @byte_pointer
      @line, deleted = byteslice!(@line, @byte_pointer, @line.bytesize - @byte_pointer)
      @byte_pointer = @line.bytesize
      @cursor = @cursor_max = calculate_width(@line)
      @kill_ring.append(deleted)
    end
  end

  private def em_kill_line(key)
    if @byte_pointer > 0
      @line, deleted = byteslice!(@line, 0, @byte_pointer)
      @byte_pointer = 0
      @kill_ring.append(deleted, true)
      @cursor_max = calculate_width(@line)
      @cursor = 0
    end
  end

  private def em_delete_or_list(key)
    if @line.empty?
      @line = nil
      finish
    elsif @byte_pointer < @line.bytesize
      splitted_last = @line.byteslice(@byte_pointer, @line.bytesize)
      mbchar = splitted_last.grapheme_clusters.first
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor_max -= width
      @line, = byteslice!(@line, @byte_pointer, mbchar.bytesize)
    end
  end

  private def em_yank(key)
    yanked = @kill_ring.yank
    if yanked
      @line = byteinsert(@line, @byte_pointer, yanked)
      yanked_width = calculate_width(yanked)
      @cursor += yanked_width
      @cursor_max += yanked_width
      @byte_pointer += yanked.bytesize
    end
  end

  private def em_yank_pop(key)
    yanked, prev_yank = @kill_ring.yank_pop
    if yanked
      prev_yank_width = calculate_width(prev_yank)
      @cursor -= prev_yank_width
      @cursor_max -= prev_yank_width
      @byte_pointer -= prev_yank.bytesize
      @line, = byteslice!(@line, @byte_pointer, prev_yank.bytesize)
      @line = byteinsert(@line, @byte_pointer, yanked)
      yanked_width = calculate_width(yanked)
      @cursor += yanked_width
      @cursor_max += yanked_width
      @byte_pointer += yanked.bytesize
    end
  end

  private def ed_clear_screen(key)
    @cleared = true
  end

  private def em_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
    end
  end

  private def ed_prev_word(key, arg = 1)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.em_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @cursor -= width
    end
    arg -= 1
    ed_prev_word(key, arg) if arg > 0
  end

  private def em_delete_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer, byte_size)
      @kill_ring.append(word)
      @cursor_max -= width
    end
  end

  private def ed_delete_prev_word(key, arg = 1)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.em_backward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer - byte_size, byte_size)
      @kill_ring.append(word, true)
      @byte_pointer -= byte_size
      @cursor -= width
      @cursor_max -= width
    end
    arg -= 1
    ed_delete_prev_word(key, arg) if arg > 0
  end

  private def ed_transpose_chars(key)
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
      end
    end
  end

  private def em_capitol_case(key)
    if @line.bytesize > @byte_pointer
      byte_size, _, new_str = Reline::Unicode.em_forward_word_with_capitalization(@line, @byte_pointer)
      before = @line.byteslice(0, @byte_pointer)
      after = @line.byteslice((@byte_pointer + byte_size)..-1)
      @line = before + new_str + after
      @byte_pointer += new_str.bytesize
      @cursor += calculate_width(new_str)
    end
  end

  private def em_lower_case(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      part = @line.byteslice(@byte_pointer, byte_size).grapheme_clusters.map { |mbchar|
        mbchar =~ /[A-Z]/ ? mbchar.downcase : mbchar
      }.join
      rest = @line.byteslice((@byte_pointer + byte_size)..-1)
      @line = @line.byteslice(0, @byte_pointer) + part
      @byte_pointer = @line.bytesize
      @cursor = calculate_width(@line)
      @cursor_max = @cursor + calculate_width(rest)
      @line += rest
    end
  end

  private def em_upper_case(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      part = @line.byteslice(@byte_pointer, byte_size).grapheme_clusters.map { |mbchar|
        mbchar =~ /[a-z]/ ? mbchar.upcase : mbchar
      }.join
      rest = @line.byteslice((@byte_pointer + byte_size)..-1)
      @line = @line.byteslice(0, @byte_pointer) + part
      @byte_pointer = @line.bytesize
      @cursor = calculate_width(@line)
      @cursor_max = @cursor + calculate_width(rest)
      @line += rest
    end
  end

  private def vi_insert(key)
    @key_actor = Reline::KeyActor::ViInsert
  end

  private def vi_add(key)
    @key_actor = Reline::KeyActor::ViInsert
    ed_next_char(key)
  end

  private def vi_command_mode(key)
    ed_prev_char(key)
    @key_actor = Reline::KeyActor::ViCommand
  end

  private def vi_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.vi_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
    end
  end

  private def vi_prev_word(key)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.vi_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @cursor -= width
    end
  end

  private def vi_end_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.vi_forward_end_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
    end
  end

  private def vi_next_big_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.vi_big_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
    end
  end

  private def vi_prev_big_word(key)
    if @byte_pointer > 0
      byte_size, width = Reline::Unicode.vi_big_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @cursor -= width
    end
  end

  private def vi_end_big_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, width = Reline::Unicode.vi_big_forward_end_word(@line, @byte_pointer)
      @byte_pointer += byte_size
      @cursor += width
    end
  end

  private def vi_delete_prev_char(key)
    if @cursor > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor -= width
      @cursor_max -= width
    end
  end

  private def vi_zero(key)
    @byte_pointer = 0
    @cursor = 0
  end

  private def ed_delete_next_char(key, arg = 1)
    unless @line.empty?
      byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
      width = Reline::Unicode.get_mbchar_width(mbchar)
      @cursor_max -= width
      if @cursor >= @cursor_max
        @byte_pointer -= byte_size
        @cursor -= width
      end
    end
    arg -= 1
    ed_delete_next_char(key, arg) if arg > 0
  end

  private def vi_to_history_line(key)
    if Reline::HISTORY.empty?
      return
    end
    if @history_pointer.nil?
      @history_pointer = 0
      @line_backup_in_history = @line
      @line = Reline::HISTORY[@history_pointer]
      @cursor_max = calculate_width(@line)
      @cursor = 0
      @byte_pointer = 0
    elsif @history_pointer.zero?
      return
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer = 0
      @line = Reline::HISTORY[@history_pointer]
      @cursor_max = calculate_width(@line)
      @cursor = 0
      @byte_pointer = 0
    end
  end

  private def vi_histedit(key)
    path = Tempfile.open { |fp|
      fp.write @line
      fp.path
    }
    system("#{ENV['EDITOR']} #{path}")
    @line = Pathname.new(path).read
    finish
    @line += "\n"
  end

  private def ed_argument_digit(key)
    if @vi_arg.nil?
      unless key.chr.to_i.zero?
        @vi_arg = key.chr.to_i
      end
    else
      @vi_arg = @vi_arg * 10 + key.chr.to_i
    end
  end

  private def vi_to_column(key, arg = 0)
    @byte_pointer, @cursor = @line.grapheme_clusters.inject([0, 0]) { |total, gc|
      # total has [byte_size, cursor]
      mbchar_width = Reline::Unicode.get_mbchar_width(gc)
      if (total.last + mbchar_width) >= arg
        break total
      elsif (total.last + mbchar_width) >= @cursor_max
        break total
      else
        total = [total.first + gc.bytesize, total.last + mbchar_width]
        total
      end
    }
  end

  private def vi_next_char(key, arg = 1)
    @waiting_proc = ->(key_for_proc) { search_next_char(key_for_proc, arg) }
  end

  private def search_next_char(key, arg)
    if key.instance_of?(Array)
      inputed_char = key.map(&:chr).join.force_encoding('UTF-8')
    else
      inputed_char = key.chr
    end
    total = nil
    @line.byteslice(@byte_pointer..-1).grapheme_clusters.each do |mbchar|
      # total has [byte_size, cursor]
      unless total
        # skip cursor point
        width = Reline::Unicode.get_mbchar_width(mbchar)
        total = [mbchar.bytesize, width]
      else
        if inputed_char == mbchar
          arg -= 1
          if arg.zero?
            break
          end
        end
        width = Reline::Unicode.get_mbchar_width(mbchar)
        total = [total.first + mbchar.bytesize, total.last + width]
      end
    end
    if total
      byte_size, width = total
      @byte_pointer += byte_size
      @cursor += width
    end
    @waiting_proc = nil
  end
end
