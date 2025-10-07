require 'rexml/document'

include REXML

class ReferenceMaker

  # CSS styles.
  Style = <<STYLE
    table {
    }
    tr:nth-child(even) {
        background-color: lightgray;
    }
    tr:nth-child(odd) {
        background-color: AntiqueWhite;
    }
    #supported {
        text-align: center;
        color: rgb(0,97,0);
        background-color: rgb(198,239,206);
    }
    #unsupported {
        text-align: center;
        color: rgb(156,0,6);
        background-color: rgb(255,199,206);
    }
    #support_unknown {
        text-align: center;
        color: black;
        background-color: lightgray;
    }
    #app_name {
        text-align: center;
        font-family: monospace;
    }

    #keys {
        text-align: center;
    }
STYLE

  # Here's the data.
  Applications = %w[reline irb ri debug]
  Sections = {
    'Commands for Moving' => [
      %w[C-a beginning-of-line true true true true],
      %w[C-e end-of-line  true true true true],
      %w[C-f forward-char true true true true],
      %w[C-b backward-char true true true true],
      %w[M-f forward-word true true true true],
      %w[M-b backward-word true true true true],
      %w[M-C-l clear-display true true true true],
      %w[C-l clear-screen true true true true],
    ],
    'Commands For Manipulating The History' => [
      ['Newline or Return', 'accept-line', 'true'],
      %w[C-p previous-history true],
      %w[C-n next-history true],
      %w[M-< beginning-of-history false],
      %w[M-> end-of-history false],
      %w[C-r reverse-search-history true],
      %w[C-s forward-search-history false],
      %w[M-p non-incremental-reverse-search-history true],
      %w[M-n non-incremental-forward-search-history true],
      %w[M-C-y yank-nth-arg false],
      ['M-. or M-_', 'yank-last-arg', 'false'],
      %w[C-o operate-and-get-next false],
    ],
    'Commands For Changing Text' => [
      ['usually C-d', 'end-of-file', 'true'],
      %w[C-d delete-char true],
      %w[Rubout backward-delete-char true],
      ['C-q or C-v', 'quoted-insert', 'false'],
      %w[M-TAB tab-insert false],
      ['a, b, A, 1, !, …', 'self-insert', 'true'],
      %w[C-t transpose-chars true],
      %w[M-t transpose-words true],
      %w[M-u upcase-word true],
      %w[M-l downcase-word true],
      %w[M-c capitalize-word true],
    ],
    'Killing and Yanking' => [
      %w[C-k kill-line true],
      ['C-x Rubout', 'backward-kill-line', 'false'],
      %w[C-u unix-line-discard true],
      %w[M-d kill-word true],
      %w[M-DEL backward-kill-word false],
      %w[C-w unix-word-rubout true],
      %w[C-y yank true],
      %w[M-y yank-pop false],
    ],
    'Specifying Numeric Arguments' => [
      ['M-0, M-1, … M--', 'digit-argument', 'true']
    ],
    'Letting Readline Type for You' => [
      %w[TAB complete true],
      %w[M-? possible-completions false],
      %w[M-* insert-completions false],
    ],
    'Keyboard Macros' => [
      ['C-x (', 'start-kbd-macro', 'false'],
      ['C-x )', 'end-kbd-macro', 'false'],
      ['C-x e', 'call-last-kbd-macro', 'false'],
    ],
    'Some Miscellaneous Commands' => [
      ['C-x C-r', 're-read-init-file'],
      %w[C-g abort false],
      ['M-A, M-B, M-x, …', 'do-lowercase-version'],
      %w[ESC prefix-meta true],
      ['C-_ or C-x C-u', 'undo', 'true'],
      %w[M-r revert-line false],
      %w[M-~ tilde-expand false],
      %w[C-@ set-mark false],
      ['C-x C-x', 'exchange-point-and-mark', 'false'],
      ['M-C-]', 'character-search-backward', 'false'],
      %w[M-# insert-comment false],
      %w[M-x execute-named-command false],
      %w[C-e emacs-editing-mode false],
      %w[M-C-j vi-editing-mode false],
    ]
  }

  # The order matters here.
  Escapes = {
    '_' => '_005f', # Must be first..
    '-' => '_002d',
    '(' => '_0028',
    ')' => '_0029',
    '<' => '_003c',
    '>' => '_003e',
    '.' => '_002e',
    ',' => '_002c',
    '…' => '_2026',
    '?' => '_003f',
    '*' => '_002a',
    '!' => '_0021',
    ']' => '_005d',
    '~' => '_007e',
    '#' => '_0023',
    '@' => '_0040',
    ' ' => '-' # Must be last.
  }

  # Make a TD element to show whether supported in the app.
  def td_for_support(supported_p)
    td = Element.new('td')
    case supported_p
    when 'true'
      td.add_attribute('id', 'supported')
      check = "\u2714".encode('utf-8')
      td.text = Text.new(check, false, nil, true)
    when 'false'
      td.add_attribute('id', 'unsupported')
      cross = "\u2716".encode('utf-8')
      td.text = Text.new(cross, false, nil, true)
    when nil
      td.add_attribute('id', 'support_unknown')
      question_mark = '?'
      td.text = Text.new(question_mark, false, nil, true)
    else
      raise value.to_s
    end
    td
  end

  # Escapes, Readline's way.
  def escape(keys, command)
    s = "#{command} (#{keys})"
    Escapes.each_pair do |old, new|
      s.gsub!(old, new)
    end
    s
  end

  class Command

    attr_accessor :keys, :name, :reline, :irb, :ri, :debug
    def initialize(command_data)
      keys, name, reline, irb, ri, debug = *command_data
      self.keys = keys
      self.name = name
      self.reline = reline
      self.irb = irb
      self.ri = ri
      self.debug = debug
    end
  end

  def initialize
    @commands = {}
    Sections.each_pair do |_, commands_in_section|
      commands_in_section.each do |command_data|
        command = Command.new(command_data)
        @commands[command.name] = command
      end
    end
    doc = Document.new
    doc.add_element(html = Element.new('html'))
    html.add_element(head = Element.new('head'))
    head.add_element(style = Element.new('style'))
    style.text = Style
    html.add_element(body = Element.new('body'))
    Sections.each do |title, commands_in_section|
      html.add_element(h2 = Element.new('h2'))
      h2.text = title
      html.add_element(table = Element.new('table'))
      table.add_element(tr = Element.new('tr'))
      %w[Keys Command].each do |heading|
        tr.add_element(th = Element.new('th'))
        th.add_attribute('rowspan', 2)
        th.text = heading
      end
      tr.add_element(th = Element.new('th'))
      th.add_attribute('colspan', 4)
      th.text = 'Applications'
      table.add_element(tr = Element.new('tr'))
      Applications.each do |heading|
        tr.add_element(th = Element.new('th'))
        th.add_attribute('width', '10%')
        th.add_attribute('id', 'app_name')
        th.text = heading
      end
      commands_in_section.each do |data|
        _, name = *data
        command = @commands[name]
        table.add_element(tr = Element.new('tr'))
        # Cell for Keys.
        tr.add_element(td = Element.new('td'))
        td.add_attribute('align', 'center')
        td.add_element(code = Element.new('code'))
        code.text = command.keys
        # Cell for command name.
        tr.add_element(td = Element.new('td'))
        td.add_element(a = Element.new('a'))
        href = 'https://tiswww.case.edu/php/chet/readline/readline.html#index-' +
               escape(command.keys, command.name)
        a.add_attribute('href', href)
        a.add_element(code = Element.new('code'))
        code.text = command.name
        # Cells for app support.
        tr.add_element(td_for_support(command.reline))
        tr.add_element(td_for_support(command.irb))
        tr.add_element(td_for_support(command.ri))
        tr.add_element(td_for_support(command.debug))
      end
      doc.write(indent: 2)
    end
  end
end


ReferenceMaker.new
