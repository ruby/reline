class Reline::Config
  DEFAULT_PATH = Pathname.new(Dir.home).join('.inputrc')

  def initialize
    @skip_section = false
  end

  def read(path = DEFAULT_PATH)
    f = File.open(path, 'rt')
    unless f
      $stderr.puts "no such file #{path}"
    end
    lines = f.readlines
    f.close

    read_lines(lines)
  end

  def read_lines(lines)
    lines.each do |line|
      if line[0, 1] == '$'
        handle_directive(line[1..-1])
        next
      end

      return if @skip_section

      if line.match(/^set +([^ ]+) +([^ ]+)/i)
        var, value = $1.downcase, $2.downcase
        bind_variable(var, value)
        next
      end

      if line =~ /"(.*)"\s*:\s*(.*)$/
        key, func_name = $1, $2
        bind_key(key, func_name)
      end
    end
  end

  def handle_directive(directive)
    directive, args = directive.split(' ')
    case directive
    when 'if'
    when 'else'
    when 'endif'
    when 'include'
    end
  end

  def bind_variable(name, value)
    case name
    when %w{
        bind-tty-special-chars
        blink-matching-paren
        byte-oriented
        completion-ignore-case
        convert-meta
        disable-completion
        enable-keypad
        expand-tilde
        history-preserve-point
        horizontal-scroll-mode
        input-meta
        mark-directories
        mark-modified-lines
        mark-symlinked-directories
        match-hidden-files
        meta-flag
        output-meta
        page-completions
        prefer-visible-bell
        print-completions-horizontally
        show-all-if-ambiguous
        show-all-if-unmodified
        visible-stats
      } then
      variable_name = :"@#{name.tr(?-, ?_)}"
      instance_variable_set(variable_name, value.nil? || value == '1' || value == 'on')
    when 'bell-style'
      @bell_style =
        case value
        when 'none', 'off'
          :none
        when 'audible', 'on'
          :audible
        when 'visible'
          :visible
        else
          :audible
        end
    when 'comment-begin'
      @comment_begin = value.dup
    when 'completion-query-items'
      @completion_query_items = value.to_i
    when 'editing-mode'
      case value
      when 'emacs'
        @keymap = @emacs_standard_keymap
        @editing_mode = @emacs_mode
      when 'vi'
      end
    when 'isearch-terminators'
      @isearch_terminators = instance_eval(value)
    when 'keymap'
      case value
      when 'emacs', 'emacs-standard', 'emacs-meta', 'emacs-ctlx'
        @keymap = @emacs_standard_keymap
      when 'vi', 'vi-move', 'vi-command'
      when 'vi-insert'
      end
    end
  end

  def bind_key(key, func_name)
  end
end
