module Reline
  def self.getc
    c = nil
    until c
      return nil if @line_editor.finished?
      result = select([$stdin], [], [], 0.1)
      next if result.nil?
      c = $stdin.read(1)
    end
    c.ord
  end

  def self.get_screen_size
    $stdin.winsize
  end

  def self.set_screen_size(rows, columns)
    $stdin.winsize = [rows, columns]
    self
  end

  def self.cursor_pos
    res = ''
    $stdin.raw do |stdin|
      $stdout << "\e[6n"
      $stdout.flush
      while (c = stdin.getc) != 'R'
        res << c if c
      end
    end
    m = res.match(/(?<row>\d+);(?<column>\d+)/)
    CursorPos.new(m[:column].to_i - 1, m[:row].to_i - 1)
  end

  def self.move_cursor_column(x)
    print "\e[#{x + 1}G"
  end

  def self.erase_after_cursor
    print "\e[J"
  end

  def self.prep
    int_handle = Signal.trap('INT', 'IGNORE')
    otio = `stty -g`.chomp
    setting = ' -echo -icrnl cbreak'
    if (`stty -a`.scan(/-parenb\b/).first == '-parenb')
      setting << ' pass8'
    end
    setting << ' -ixoff'
    `stty #{setting}`
    Signal.trap('INT', int_handle)
    otio
  end

  def self.deprep(otio)
    int_handle = Signal.trap('INT', 'IGNORE')
    `stty #{otio}`
    Signal.trap('INT', int_handle)
  end
end
