require 'reline/kill_ring'
require 'reline/unicode'

require 'io/console'
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
    @editing_space = Struct.new(:height, :x, :y).new(1, 0, 0)
    @byte_pointer = 0
    @line = String.new(encoding: Encoding.default_external)
    @key_actor = key_actor
    @finished = false
    @cleared = false
    @history_pointer = nil
    @line_backup_in_history = nil
    @kill_ring = Reline::KillRing.new
    @vi_arg = nil
    @multibyte_buffer = String.new(encoding: 'ASCII-8BIT')
    @meta_prefix = false
    @waiting_proc = nil
    @completion_journey_data = nil
    @completion_state = CompletionState::NORMAL
  end

  def print_in_space(str)
    #pos = Reline.cursor_pos
    str.grapheme_clusters.each do |c|
      print c
      #new_pos = Reline.cursor_pos
      #if new_pos.x < pos.x # wrapped
      #  @editing_space.height += 1
      #end
      #pos = new_pos
    end
    #pos
    Reline.cursor_pos
  end

  def rerender
    return unless @line
    if @vi_arg
      prompt = "(arg: #{@vi_arg}) "
    else
      prompt = @prompt
    end
    if @cleared
      print "\e[2J"
      print "\e[1;1H"
      @cleared = false
    else
      if @editing_space.y > 0
        print "\e[#{@editing_space.y}A" if @editing_space.y > 1
        print @editing_space.height.times.map{"\e[2K"}.join("\e[1B")
        print "\e[#{@editing_space.height - 1}A" if @editing_space.height > 1
        print "\e[1G"
      else
        #print "\e[1G"
        Reline.move_cursor_column(0)
      end
    end
    @editing_space.height = 1
    print_in_space(prompt)
    pos = print_in_space(@line.byteslice(0, @byte_pointer))
    @editing_space.x = pos.x
    @editing_space.y = @editing_space.height - 1
    print_in_space(@line.byteslice(@byte_pointer..-1))
    Reline.erase_after_cursor
    Reline.move_cursor_column(@editing_space.x)
  end

  private def menu(target, list)
    puts
    list.each do |item|
      puts item
    end
  end

  private def complete_internal_proc(list, is_menu)
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

  private def complete(list)
    case @completion_state
    when CompletionState::NORMAL, CompletionState::JOURNEY
      @completion_state = CompletionState::COMPLETION
    end
    is_menu = (@completion_state == CompletionState::MENU)
    result = complete_internal_proc(list, is_menu)
    return if result.nil?
    target, preposing, completed, postposing = result
    return if completed.nil?
    if target <= completed and @completion_state == CompletionState::COMPLETION
      @completion_state = CompletionState::MENU
      if target < completed
        @line = preposing + completed + postposing
        line_to_pointer = preposing + completed
        @byte_pointer = line_to_pointer.bytesize
      end
    end
  end

  private def move_completed_list(list, direction)
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
      @byte_pointer = line_to_pointer.bytesize
    end
  end

  def normal_char(key)
    @multibyte_buffer << key
    if @multibyte_buffer.size > 1
      if @multibyte_buffer.dup.force_encoding(Encoding.default_external).valid_encoding?
        key = @multibyte_buffer.dup.force_encoding(Encoding.default_external)
        @multibyte_buffer.clear
      else
        # invalid
        return
      end
    else # single byte
      return if key >= 128 # maybe, first byte of multi byte
      if @meta_prefix
        key |= 0b10000000 if key.nobits?(0b10000000)
        @meta_prefix = false
      end
      method_symbol = @key_actor.get_method(key)
      if method_symbol and respond_to?(method_symbol, true)
        method_obj = method(method_symbol)
      end
      @multibyte_buffer.clear
    end
    if @vi_arg
      if key.chr =~ /[0-9]/
        ed_argument_digit(key)
      else
        if ARGUMENTABLE.include?(method_symbol) and method_obj
          method_obj.(key, @vi_arg)
        elsif @waiting_proc
          @waiting_proc.(key)
        elsif method_obj
          method_obj.(key)
        else
          ed_insert(key)
        end
        @kill_ring.process
        @vi_arg = nil
      end
    elsif @waiting_proc
      @waiting_proc.(key)
      @kill_ring.process
    elsif method_obj
      method_obj.(key)
      @kill_ring.process
    else
      ed_insert(key)
    end
  end

  def input_key(key)
    completion_occurs = false
    if [Reline::KeyActor::Emacs, Reline::KeyActor::ViInsert].include?(@key_actor) and key == "\C-i".ord
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
      normal_char(key)
    end
    unless completion_occurs
      @completion_state = CompletionState::NORMAL
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

  private def ed_insert(key)
    if key.instance_of?(String)
      @line = byteinsert(@line, @byte_pointer, key)
      @byte_pointer += key.bytesize
    else
      @line = byteinsert(@line, @byte_pointer, key.chr)
      @byte_pointer += 1
    end
  end
  alias_method :ed_digit, :ed_insert

  private def ed_next_char(key, arg = 1)
    byte_size = next_byte_size
    if Reline::KeyActor::ViCommand == @key_actor
      ignite = ((@byte_pointer + byte_size) < @line.bytesize)
    else
      ignite = (@byte_pointer < @line.bytesize)
    end
    if ignite
      mbchar = @line.byteslice(@byte_pointer, byte_size)
      @byte_pointer += byte_size
    end
    arg -= 1
    ed_next_char(key, arg) if arg > 0
  end

  private def ed_prev_char(key, arg = 1)
    if @byte_pointer > 0
      @byte_pointer -= prev_byte_size
    end
    arg -= 1
    ed_prev_char(key, arg) if arg > 0
  end

  private def ed_move_to_beg(key)
    @byte_pointer = 0
  end

  private def ed_move_to_end(key)
    @byte_pointer = @line.bytesize
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
      @byte_pointer = @line.bytesize
    elsif @history_pointer.zero?
      return
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer -= 1
      @line = Reline::HISTORY[@history_pointer]
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
      @byte_pointer = @line.bytesize
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer += 1
      @line = Reline::HISTORY[@history_pointer]
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
    if @byte_pointer > 0
      byte_size = prev_byte_size
      @byte_pointer -= byte_size
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
    end
  end

  private def ed_kill_line(key)
    if @line.bytesize > @byte_pointer
      @line, deleted = byteslice!(@line, @byte_pointer, @line.bytesize - @byte_pointer)
      @byte_pointer = @line.bytesize
      @kill_ring.append(deleted)
    end
  end

  private def em_kill_line(key)
    if @byte_pointer > 0
      @line, deleted = byteslice!(@line, 0, @byte_pointer)
      @byte_pointer = 0
      @kill_ring.append(deleted, true)
    end
  end

  private def em_delete_or_list(key)
    if @line.empty?
      @line = nil
      finish
    elsif @byte_pointer < @line.bytesize
      splitted_last = @line.byteslice(@byte_pointer, @line.bytesize)
      mbchar = splitted_last.grapheme_clusters.first
      @line, = byteslice!(@line, @byte_pointer, mbchar.bytesize)
    end
  end

  private def em_yank(key)
    yanked = @kill_ring.yank
    if yanked
      @line = byteinsert(@line, @byte_pointer, yanked)
      @byte_pointer += yanked.bytesize
    end
  end

  private def em_yank_pop(key)
    yanked, prev_yank = @kill_ring.yank_pop
    if yanked
      @byte_pointer -= prev_yank.bytesize
      @line, = byteslice!(@line, @byte_pointer, prev_yank.bytesize)
      @line = byteinsert(@line, @byte_pointer, yanked)
      @byte_pointer += yanked.bytesize
    end
  end

  private def ed_clear_screen(key)
    @cleared = true
  end

  private def em_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
    end
  end

  private def ed_prev_word(key, arg = 1)
    if @byte_pointer > 0
      byte_size, = Reline::Unicode.em_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
    end
    arg -= 1
    ed_prev_word(key, arg) if arg > 0
  end

  private def em_delete_next_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.em_forward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer, byte_size)
      @kill_ring.append(word)
    end
  end

  private def ed_delete_prev_word(key, arg = 1)
    if @byte_pointer > 0
      byte_size, = Reline::Unicode.em_backward_word(@line, @byte_pointer)
      @line, word = byteslice!(@line, @byte_pointer - byte_size, byte_size)
      @kill_ring.append(word, true)
      @byte_pointer -= byte_size
    end
    arg -= 1
    ed_delete_prev_word(key, arg) if arg > 0
  end

  private def ed_transpose_chars(key)
    if @byte_pointer > 0
      if @line.bytesize > @byte_pointer
        byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
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
      byte_size, = Reline::Unicode.vi_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
    end
  end

  private def vi_prev_word(key)
    if @byte_pointer > 0
      byte_size, = Reline::Unicode.vi_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
    end
  end

  private def vi_end_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.vi_forward_end_word(@line, @byte_pointer)
      @byte_pointer += byte_size
    end
  end

  private def vi_next_big_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.vi_big_forward_word(@line, @byte_pointer)
      @byte_pointer += byte_size
    end
  end

  private def vi_prev_big_word(key)
    if @byte_pointer > 0
      byte_size, = Reline::Unicode.vi_big_backward_word(@line, @byte_pointer)
      @byte_pointer -= byte_size
    end
  end

  private def vi_end_big_word(key)
    if @line.bytesize > @byte_pointer
      byte_size, = Reline::Unicode.vi_big_forward_end_word(@line, @byte_pointer)
      @byte_pointer += byte_size
    end
  end

  private def vi_delete_prev_char(key)
    if @byte_pointer > 0
      byte_size = Reline::Unicode.get_prev_mbchar_size(@line, @byte_pointer)
      @byte_pointer -= byte_size
      @line, = byteslice!(@line, @byte_pointer, byte_size)
    end
  end

  private def vi_zero(key)
    @byte_pointer = 0
  end

  private def ed_delete_next_char(key, arg = 1)
    unless @line.empty?
      byte_size = Reline::Unicode.get_next_mbchar_size(@line, @byte_pointer)
      @line, mbchar = byteslice!(@line, @byte_pointer, byte_size)
      if @byte_pointer >= @line.bytesize
        @byte_pointer -= byte_size
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
      @byte_pointer = 0
    elsif @history_pointer.zero?
      return
    else
      Reline::HISTORY[@history_pointer] = @line
      @history_pointer = 0
      @line = Reline::HISTORY[@history_pointer]
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
    @byte_pointer = @line.grapheme_clusters.inject(0) { |total, gc|
      if (total + gc.bytebyte) >= arg
        break total
      elsif (total + gc.bytesize) >= @line.bytesize
        break total
      else
        total + gc.bytesize
      end
    }
  end

  private def vi_next_char(key, arg = 1)
    @waiting_proc = ->(key_for_proc) { search_next_char(key_for_proc, arg) }
  end

  private def search_next_char(key, arg)
    if key.instance_of?(String)
      inputed_char = key
    else
      inputed_char = key.chr
    end
    total = nil
    @line.byteslice(@byte_pointer..-1).grapheme_clusters.each do |mbchar|
      unless total
        # skip cursor point
        total = mbchar.bytesize
      else
        if inputed_char == mbchar
          arg -= 1
          if arg.zero?
            break
          end
        end
        total += mbchar.bytesize
      end
    end
    if total
      @byte_pointer += total
    end
    @waiting_proc = nil
  end
end
