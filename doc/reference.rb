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
    %w[M-C-l clear-display true],
    %w[C-l clear-screen false],
  ],
  'Commands For Manipulating The History' => [
    ['Newline or Return', 'accept-line'],
    %w[C-p previous-history],
    %w[C-n next-history],
    %w[M-< beginning-of-history],
    %w[M-> end-of-history],
    %w[C-r reverse-search-history],
    %w[C-s forward-search-history],
    %w[M-p non-incremental-reverse-search-history],
    %w[M-n non-incremental-forward-search-history],
    %w[M-C-y yank-nth-arg],
    ['M-. or M-_', 'yank-last-arg'],
    %w[C-o operate-and-get-next],
  ],
  'Commands For Changing Text' => [
    ['usually C-d', 'end-of-file'],
    %w[C-d delete-char],
    %w[Rubout backward-delete-char],
    ['C-q or C-v', 'quoted-insert'],
    %w[M-TAB tab-insert],
    ['a, b, A, 1, !, …', 'self-insert'],
    %w[C-t transpose-chars],
    %w[M-t transpose-words],
    %w[M-u upcase-word],
    %w[M-l downcase-word],
    %w[M-c capitalize-word],
  ],
  'Killing and Yanking' => [
    %w[C-k kill-line],
    ['C-x Rubout', 'backward-kill-line'],
    %w[C-u unix-line-discard],
    %w[M-d kill-word],
    %w[M-DEL backward-kill-word],
    %w[C-w unix-word-rubout],
    %w[C-y yank],
    %w[M-y yank-pop],
  ],
  'Specifying Numeric Arguments' => [
    ['M-0, M-1, … M--', 'digit-argument']
  ],
  'Letting Readline Type for You' => [
    %w[TAB complete],
    %w[M-? possible-completions],
    %w[M-* insert-completions],
  ]
}
Headings = %w[ Keys Command reline debug irb ri ]

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

