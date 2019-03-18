require 'pathname'

class Reline::Config
  DEFAULT_PATH = Pathname.new(Dir.home).join('.inputrc')

  def initialize
    @skip_section = nil
    @if_stack = []
  end

  def read(file = DEFAULT_PATH)
    if file.respond_to?(:readlines)
      lines = file.readlines
    else
      begin
        File.open(file, 'rt') do |f|
          lines = f.readlines
        end
      rescue Errno::ENOENT
        $stderr.puts "no such file #{file}"
        return nil
      end
    end

    read_lines(lines)
    self
  end

  def read_lines(lines)
    lines.each do |line|
      line = line.chomp
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

      if line =~ /\s*(.*)\s*:\s*(.*)\s*$/
        key, func_name = $1, $2
        bind_key(key, func_name)
      end
    end
  end

  def handle_directive(directive)
    directive, args = directive.split(' ')
    case directive
    when 'if'
      condition = false
      case args.first
      when 'mode'
      when 'term'
      when 'version'
      when 'application'
      when 'variable'
      end
      unless @skip_section.nil?
        @if_stack << @skip_section
      end
      @skip_section = !condition
    when 'else'
      @skip_section = !@skip_section
    when 'endif'
      @skip_section = nil
      unless @if_stack.empty?
        @skip_section = @if_stack.pop
      end
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
    if key =~ /"(.*)"/
      keyseq = parse_keyseq($1)
    else
      keyseq = nil
    end
    if func_name =~ /"(.*)"/
      func = parse_keyseq($1)
    else
      func = func_name.to_sym # It must be macro.
    end
    [keyseq, func]
  end

  def key_notation_to_char(notation)
    case notation
    when /\\C-[a-z_]/
    when /\\M-[a-z_]/
    when /\\C-M-[a-z_]/, /\\M-C-[a-z_]/
    when "\\\d{1,3}"
    when "\\x\h{1,2}"
    when "\e" then ?\e
    when "\\\\" then ?\
    when "\\\"" then ?"
    when "\\'" then ?'
    when "\\a" then ?\a
    when "\\b" then ?\b
    when "\\d" then ?\d
    when "\\f" then ?\f
    when "\\n" then ?\n
    when "\\r" then ?\r
    when "\\t" then ?\t
    when "\\v" then ?\v
    else notation
    end
  end

  def parse_keyseq(str)
    ret = String.new(encoding: 'ASCII-8BIT')
    while str =~ /(\\C-[a-z_]|\\M-[a-z_]|\\C-M-[a-z_]|\\M-C-[a-z_]|\e|\\\\|\\"|\\'|\\a|\\b|\\d|\\f|\\n|\\r|\\t|\\v|\\\d{1,3}|\\x\h{1,2}|.)/
      ret << key_notation_to_char($&)
      str = $'
    end
    ret
  end
end
