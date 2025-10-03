require 'rexml/document'

include REXML

Sections = {
  'Commands for Moving' => [
    %w[C-a beginning-of-line true],
    %w[C-e end-of-line true],
    %w[C-f forward-char true],
    %w[C-b backward-char true],
    %w[M-f forward-word true],
    %w[M-b backward-word true],
    %w[M-C-l clear-display false],
    %w[C-l clear-screen true],
  ],
  'Commands For Manipulating The History' => [
    ['Newline or Return', 'accept-line', 'true'],
    %w[C-p previous-history false],
    %w[C-n next-history false],
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
    %w[C-t transpose-chars false],
    %w[M-t transpose-words false],
    %w[M-u upcase-word false],
    %w[M-l downcase-word false],
    %w[M-c capitalize-word false],
  ],
  'Killing and Yanking' => [
    %w[C-k kill-line true],
    ['C-x Rubout', 'backward-kill-line', 'false'],
    %w[C-u unix-line-discard false],
    %w[M-d kill-word true],
    %w[M-DEL backward-kill-word true],
    %w[C-w unix-word-rubout true],
    %w[C-y yank true],
    %w[M-y yank-pop true],
  ],
  'Specifying Numeric Arguments' => [
    ['M-0, M-1, … M--', 'digit-argument', 'false']
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
    ['C-x C-r', 're-read-init-file', 'false'],
    %w[C-g abort true],
    ['M-A, M-B, M-x, …', 'do-lowercase-version', 'false'],
    %w[ESC prefix-meta true],
    ['C-_ or C-x C-u', 'undo', 'false'],
    %w[M-r revert-line false],
    %w[M-~ tilde-expand false],
    %w[C-@ set-mark false],
    ['C-x C-x', 'exchange-point-and-mark', 'false'],
    ['M-C-]', 'character-search-backward', 'false'],
    %w[M-# insert-comment false],
    %w[M-x execute-named-command false],
    %w[C-e emacs-editing-mode true],
    %w[M-C-j vi-editing-mode false],
  ]
}
Headings = %w[ Keys Command reline irb ri debug]

def td_for(value)
  td = Element.new('td')
  td.add_attribute('align', 'center')
  case value
  when 'true'
    font = Element.new('font')
    font.add_attribute('color', 'green')
    td.add_element(font)
    td.text = 'Yes'
  when 'false'
    font = Element.new('font')
    font.add_attribute('color', 'red')
    td.add_element(font)
    td.text = 'No'
  when nil
    font = Element.new('font')
    font.add_attribute('color', 'gray')
    td.add_element(font)
    td.text = '?'
  else
    raise value.to_s
  end
  td
end

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
  ' ' => '-'      # Must be last.
}

def escape(keys, command)
  s = "#{command} (#{keys})"
  Escapes.each_pair do |old, new|
    s.gsub!(old, new)
  end
  s
end

doc = Document.new
doc.add_element(html = Element.new('html'))
html.add_element(head = Element.new('head'))
html.add_element(body = Element.new('body'))
Sections.each do |title, commands|
  html.add_element(h2 = Element.new('h2'))
  h2.text = title
  html.add_element(table = Element.new('table'))
  table.add_attribute('border', 1)
  table.add_element(tr = Element.new('tr'))
  Headings.each_with_index do |heading, i|
    tr.add_element(th = Element.new('th'))
    th.add_attribute('width', '10%') if i > 1
    th.text = heading
  end
  commands.each do |data|
    keys, command, reline, debug, irb, ri = data
    table.add_element(tr = Element.new('tr'))
    # Cell for Keys.
    tr.add_element(td = Element.new('td'))
    td.add_attribute('align', 'center')
    td.add_element(code = Element.new('code'))
    code.text = keys
    # Cell for Command.
    tr.add_element(td = Element.new('td'))
    td.add_element(a = Element.new('a'))
    href = 'https://tiswww.case.edu/php/chet/readline/readline.html#index-' +
           escape(keys, command)
    a.add_attribute('href', href)
    a.add_element(code = Element.new('code'))
    code.text = command

    tr.add_element(td_for(reline))
    tr.add_element(td_for(debug))
    tr.add_element(td_for(irb))
    tr.add_element(td_for(ri))

  end
end

doc.write(indent: 2)

