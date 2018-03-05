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

  private def ed_insert(key)
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
  alias_method :ed_digit, :ed_insert
end
