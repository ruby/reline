class Reline::Readline
  def initialize(prompt, add_hist)
    @prompt = prompt
    @add_hist = add_hist
    @line_editor = Reline::LineEditor.new(Reline::KeyActor::ViInsert, prompt)
  end

  def getc
    c = nil
    until c
      return nil if @line_editor.finished?
      result = select([$stdin], [], [], 0.1)
      next if result.nil?
      c = $stdin.read(1)
    end
    c.ord
  end

  def prep
    int_handle = Signal.trap('INT', 'IGNORE')
    @otio = `stty -g`.chomp
    setting = ' -echo -icrnl cbreak'
    if (`stty -a`.scan(/-parenb\b/).first == '-parenb')
      setting << ' pass8'
    end
    setting << ' -ixoff'
    `stty #{setting}`
    Signal.trap('INT', int_handle)
  end

  def deprep
    int_handle = Signal.trap('INT', 'IGNORE')
    `stty #{@otio}`
    Signal.trap('INT', int_handle)
  end

  def run
    prep

    begin
      while c = getc
        @line_editor.input_key(c)
        break if @line_editor.finished?
      end
      if @add_hist and @line_editor.line and @line_editor.line.chomp.size > 0
        Reline::HISTORY << @line_editor.line.chomp
      end
    rescue StandardError => e
      deprep
      raise e
    end

    deprep

    @line_editor.line
  end
end
