# For Users

This page is for the user of a Reline application.

## In Brief

This section is a quick reference for the Reline commands;
details at the links.

### Moving the Cursor

- `C-f` or `→`:    [Character forward]  [character forward].
- `C-b` or `←`:    [Character backward] [character backward].
- `M-f`:           [Word forward]       [word forward].
- `M-b`:           [Word backward]      [word backward].
- `C-a` or `Home`: [Beginning of line]  [beginning of line]
- `C-e` or `End`:  [End of line]        [end of line]
- `C-l`:           [Clear screen]       [clear screen].
- `M-C-l`:         [Clear display]      [clear display].

### Changing Text

- Any printable character: [Insert character][insert character].
- `Delete`: [Delete character forward][delete character forward].
- `C-d`: [Delete character forward (non-empty line)][delete character forward (non-empty line)].
- `Backspace`: [Delete character backward][delete character backward].
- `C-t`: [Transpose characters][transpose characters].
- `M-t`: [Transpose words][transpose words].
- `M-u`: [Upcase word][upcase word].
- `M-l`: [Downcase word][downcase word].
- `M-c`: [Capitalize word][capitalize word].

### Killing and Yanking

- `C-k': [Kill line forward][kill line forward].
- `C-u': [Kill line backward][kill line backward].
- `M-d': [Kill word forward][kill word forward].
- `C-w': [Kill word backward][kill word backward].
- `C-y': [Yank last kill][yank last kill].

### Manipulating History

- `Enter`:      [Accept line]    [accept line].
- `C-p` or `↑`: [Previous command] [previous command].
- `C-n` or `↓`: [Next command]     [next command].
- `C-r`:        [Reverse search]   [reverse search].

### Completing Words

- `Tab': [Complete word][complete word].
- `Tab Tab': [Show completions][show completions].

## Reline Application

A _Reline application_ is a Ruby
[console application][console application]
that uses module Reline.

Such an application typically implements a [REPL][repl]
(Read-Evaluate-Print Loop)
that allows you to type a command, get a response,
type another command, get another response, and so on.

A Reline application by default supports:

- [Commands for moving the cursor][commands for moving the cursor].
- [Commands for changing text][commands for changing text].
- [Commands for killing and yanking][commands for killing and yanking].

A Reline application may support:

- [Word completion][word completion] (if enabled).
- [Command history][command history] (if enabled).

## Reline in Ruby

Ruby itself includes these Reline applications:

- [irb][irb]: Interactive Ruby.
- [debug][debug]: Ruby debugger.
- [ri][ri]: Ruby information.

## Reline Defaults

Note that this page describes the _default_ usages for Reline,
with both [command history][command history] and [word completion][word completion] enabled,
as in this simple "echo" program:

```
require 'reline'

puts 'Welcome to the Echo program!'
puts '  To exit, type Ctrl-d in empty line.'

# Words for completion.
Words = %w[ foo_foo foo_bar foo_baz qux ]
Reline.completion_proc = proc { |word| Words }

# REPL (Read-Evaluate-Print Loop).
while line = Reline.readline(prompt = 'echo> ', history = true)
  puts "You typed: '#{line.chomp}'."
end
```

Other console applications that use module Reline may have implemented different usages.

## About the Examples

Examples on this page are derived from the echo program above.

## Notations

Reline is basically a domain-specific language,
implemented via certain keys, control characters, and meta characters.

To denote these here in the documentation,
we use certain notations.

### Keys

Arrow keys:

- `←` denotes the left-arrow key.
- `→` denotes the right-arrow key.
- `↑` denotes the up-arrow key.
- `↓` denotes the down-arrow key.
  
Other keys:

- `Alt` denotes the Alt key.
- `Backspace` denotes the Backspace key.
- `Ctrl` denotes the Control key.
- `Delete` denotes the Delete key.
- `End` denotes the End key.
- `Enter` denotes the Enter key.
- `Escape` denotes the Escape key.
- `Home` denotes the Home key.
- `Tab` denotes the Tab key.

### Control Characters

`C-k` (pronounced "Control-k") denotes the input produced
when `Ctrl` is depressed (held down),
then the `k` key is then pressed, and both are released.

Almost any character can have a "control" version:
`C-a`, `C-{`, `C-]`, etc.

### Meta Characters

`M-k` (pronounced "Meta-k") denotes the input produced
when the `Alt` is depressed (held down),
then the `k` key is then pressed, and both are released.

Almost any character can have "meta" version:
`M-c`, `M->`, `M-#`, etc.

An alternative to using the `Alt` key is the `Escape` key:
press the `Escape` key _before_ the character key.

## Repetition

A command may be prefixed by an integer argument
that specifies the number of times the command is to be executed.

Some commands support repetition; others do not.
See individual commands.

If repetition for the command is supported and a repetition value of `n` is given,
the command is executed `n` times.

It the repetition for the command is not supported, the repetition prefix is ignored.

## Undo

The undo command (`C-_`) "undoes" the action of a previous command (if any)
on the _current_ command line;
nothing is ever undone in an already-entered line.

In general, an "undoable" command is one that moved the cursor or modified text.
Other commands are not undoable, but instead "passes through" the command to earlier commands;
see below.

### Immediate Undo

When the undo command is given and the immediately preceding command is undoable,
that preceding command is undone.

### "Pass-Through" Undo

When the undo command is given and the immediately preceding command is not undoable,
the undo command "passes through" to commands given earlier.
Reline searches backward through the most recent commands for the current line:

- When an undoable command is found, that command is undone, and the search ends.
- If no such command is found, the undo command is ignored.

## Command-Line Editing

### Killing and Yanking

_Killing_ means deleting text from the current line
and saving it in a kill buffer for potential later use (by _yanking_).

_Yanking_ means inserting previously-killed text into the current line.
Yanked text is copied from the kill buffer.

Killed text is put onto the _kill buffer_:

- For a kill command that is preceded by another kill command,
  the killed text is appended to the text already in the kill buffer.
  Thus, any number of consecutive kills save killed text as a single string.
- For a kill command that is _not_ preceded by another kill command,
  the killed text replaces the text in the kill buffer.

The kill buffer is not associated with a particular command line;
text killed from a the current line is available for yanking into later command lines.

### Word Completion

A Reline application may support command word completion,
which is implemented via the `Tab` command.

The example [echo program][reline defaults] has loaded a collection of words
that it uses for completing words:

```ruby
Words = %w[ foo_foo foo_bar foo_baz qux ]

```

In the echo program, typing `'f'` followed by `Tab`
lets the program do a partial word completion, adding `'oo_'` to form `'foo_'`.

The program can add the partial completion `'oo_'`
because all the available words that begin with `'f'` also begin with `'foo_'`.

But it can't complete the word because there are multiple words that begin with `'foo_'`.

If we add `'b'` and `Tab`, the program can add `'bar'` to form the complete word `'foo_bar'`,
because that's the only word that begins `'foo_b'`.

To see the completion possibilities, type `Tab` twice;
this example types `f` followed by two `Tab`s:

```
echo> foo_
foo_bar  foo_baz  foo_foo
```

Word completion works on the current word in the line,
which may not be the only word;
this example types `'xyzzy f'` followed by two `Tab`s
to get the possible completions:

```ruby
echo> xyzzy foo_
foo_bar  foo_baz  foo_foo
```

### Command History

A Reline application may support command history.

An easy way to find out whether it does:
after entering one or more commands, press key `↑`:

- Yes, if you now see the most recently entered command; read on.
- No, if you see no change; this section does not apply.

#### Traversing History

Use any number of `C-p` or `↑` commands to move upward in the command history;
the first such command displays the most recent command,
the second, the next-most-recent command,
and so forth.

When in the history,
use any number of `C-n` or `↓` commands to move downward in the command history.

At any time, if the displayed command is exactly the one you want to execute,
press `Enter`.

Otherwise, You can edit the displayed command
using the various Reline [editing tools][command-line editing] (including Undo),
then `Enter` it when satisfied.

#### Searching History

Use command `C-r` to search upward in the history.

When you give that command, Reline displays this:

```ruby
(reverse-i-search)`':
```

The command is interactive in the sense that if you type `a`,
Reline displays the first found command that matches the `a`.

At that point you can:

- Give another `C-r` command; Reline searches upward for the next command matching `a`.
- Type another character, say `b`; Reline searches upward for a command matching `ab`.

### Exiting the Application

To exit the application, use command `C-d` on an empty command line.

## Command Line Commands

### Commands for Moving the Cursor

#### `C-f` or `→`: Character Forward

- **Action:** Move the cursor forward one character.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:** Do nothing if already at end-of-line.

#### `C-b` or `←`: Character Backward

- **Action:** Move the cursor backward one character.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:** Do nothing if already at beginning-of-line.

#### `M-f`: Word Forward

- **Action:** Move the cursor forward one word.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:**

    - If the cursor is in a word, move to the end of that word;
    - Otherwise (cursor at a space, for example), move to the end of the next word on the right.

#### `M-b`: Word Backward

- **Action:** Move the cursor backward one word.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:**

    - If the cursor is in a word, move to the beginning of that word.
    - Otherwise (cursor at a space, for example), move to the beginning of the next word on the left.

#### `C-a`: Beginning of Line

- **Action:**: Move the cursor to the beginning of the line.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:** Do nothing if already at beginning-of-line.

#### `C-e`: End of Line

- **Action:** Move the cursor to the end of the line.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].
- **Details:** Do nothing if already at end-of-line.

#### `C-l`: Clear Screen

- **Action:** Clear the screen, then redraw the current line,
  leaving the current line at the top of the screen.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].

#### `M-C-l`: Clear Display

- **Action:** Like `C-l`, but also clear the terminal’s scrollback buffer if possible.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [pass-through undo][pass-through undo].

### Commands for Changing Text

#### Any Printable Character: Insert Character

- **Action:** Insert the character at the cursor position. 
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:** Move the trailing string (if any) one character width to the right, to "open a gap";
  place the cursor immediately after the inserted character.

#### `Delete`: Delete Character Forward

- **Action:** Delete the character at the cursor.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at end-of-line: do nothing.
    - Otherwise, delete the character at the cursor,
      move the trailing string (if any) one character to the left, to "close the gap",
      and leave the cursor in place.

#### `C-d`: Delete Character Forward (Non-Empty Line)

Like `Delete` if line non-empty;
otherwise, [exit the application][exiting the application].

#### `Backspace`: Delete Character Backward

- **Action:** Delete the character before the cursor.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at beginning-of-line: do nothing.
    - Otherwise, move the cursor and the trailing string (if any) one character to the left,
      to "close the gap."

#### `C-t`: Transpose Characters

- **Action:** Transpose two characters (by exchanging their positions).
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at beginning-of-line, or if there is only one character, do nothing.
    - Otherwise, if at end-of-line, transpose the last two characters; leave the cursor in place.
    - Otherwise, transpose the single characters before and after the cursor
      and move the cursor to the end of the transposed pair.

#### `M-t`: Transpose Words

- **Action:**: Transpose two words (by exchanging their positions).
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at the beginning-of-line, or if in the first word, or if there is only one word, do nothing.
    - If in a non-first word, or at the beginning or end of the last word,
      transpose that word and the preceding word and move the cursor to the end of the word pair.
    - If at the end of a non-last word,
      transpose that word and the following word and move the cursor to the end of the word pair.
  
#### `M-u`: Upcase Word

- **Action:**: Change word to uppercase.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, upcase the entire word and move cursor to the end of that word.
    - If in a word, upcase the rightward part of the word and move cursor to the end of that word.
    - If at the end of a word, upcase the next word and move cursor to the end of that word.

#### `M-l`: Downcase Word

- **Action:**: Change word to lowercase.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, downcase the entire word and move cursor to the end of that word.
    - If in a word, downcase the rightward part of the word and move cursor to the end of that word.
    - If at the end of a word, downcase the next word and move cursor to the end of that word.

#### `M-c`: Capitalize Word

- **Action:**: Capitalize word.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, upcase its first character and move cursor to the end of that word.
    - If in a word, upcase the next character and move cursor to the end of that word.
    - If at the end of a word, upcase the first character of the next word and move cursor to the end of that word.

### Commands for Killing and Yanking

#### `C-k`: Kill Line Forward

- **Action:**: Kill from cursor to end-of-line and place cursor at end-of-line.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**: If at end-of-line, do nothing.

#### `C-u`: Kill Line Backward

- **Action:**: Kill from cursor to beginning-of-line and place cursor at beginning-of-line.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**: If at beginning-of-line, do nothing.

#### `M-d`: Kill Word Forward

- **Action:**: Kill line from cursor to end-of-word.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, kill the word and leave the cursor in place.
    - If in a word, kill the rest of the word and leave the cursor in place.
    - If at the end of a word, kill the next word and leave the cursor in place.

#### `C-w`: Kill Word Backward

- **Action:**: Kill line from cursor to beginning-of-word.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at beginning-of-line, do nothing.
    - If at the beginning of a word, kill the previous word and place the cursor at the left of the deletion.
    - If in a word, kill the leftward part of the word and place the cursor at the left of the deletion.
    - If at the end of a word, kill the word and place the cursor at the left of the deletion.

#### `C-y`: Yank Last Kill

- **Action:**: Insert killed text at the cursor and place the cursor at the end of the inserted text.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**: Do nothing if the kill buffer is empty.

### Commands for Manipulating the History

####  `Enter`: Accept Line

- **Action:**: Enter the command on the line.
- **Repetition?:** [No][repetition].
- **Undoable?:** No.
- **Details:**:

    - The command line may be empty or contain only whitespace.
    - The cursor need not be at the end-of-line.

#### `C-p` or `↑`: Previous Command

- **Action:**: Display the immediately preceding command.
- **Repetition?:** [No][repetition].
- **Undoable?:** No.
- **Details:**: See [Traversing History][traversing history].

#### `C-n` or `↓`: Next Command

- **Action:**: Display the immediately following command.
- **Repetition?:** [No][repetition].
- **Undoable?:** No.
- **Details:**: See [Traversing History][traversing history].

#### `C-r`: Reverse Search

- **Action:**: Search upward in history.
- **Repetition?:** [No][repetition].
- **Undoable?:** No.
- **Details:**: See [Searching History][searching history].

### Commands for Completing Words

#### `Tab`: Complete Word

- **Action:**: Complete word.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**: See [Word Completion][word completion].

#### `Tab Tab`: Show Completions

- **Action:**: Show completions.
- **Repetition?:** [No][repetition].
- **Undoable?:** No.
- **Details:**: See [Word Completion][word completion].

[commands for moving the cursor]:        rdoc-ref:@Commands+for+Moving+the+Cursor
[commands for manipulating the history]: rdoc-ref:@Commands+for+Manipulating+the+History
[commands for changing text]:            rdoc-ref:@Commands+for+Changing+Text
[commands for killing and yanking]:      rdoc-ref:@Commands+for+Killing+and+Yanking
[commands for completing words]:         rdoc-ref:@Commands+for+Word+Completion

[in brief]:                rdoc-ref:@In+Brief
[reline defaults]:         rdoc-ref:@Reline+Defaults
[undo]:                    rdoc-ref:@Undo
[immediate undo]:          rdoc-ref:@Immediate+Undo
[pass-through undo]:       rdoc-ref:@22Pass-Through-22+Undo
[repetition]:              rdoc-ref:@Repetition
[command-line editing]:    rdoc-ref:@Command-Line+Editing
[command history]:         rdoc-ref:@Command+History
[traversing history]:      rdoc-ref:@Traversing+History
[searching history]:       rdoc-ref:@Searching+History
[word completion]:         rdoc-ref:@Word+Completion
[exiting the application]: rdoc-ref:@Exiting+the+Application

[console application]: https://en.wikipedia.org/wiki/Console_application
[debug]:               https://github.com/ruby/debug
[irb]:                 https://ruby.github.io/irb/index.html
[repl]:                https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop
[ri]:                  https://ruby.github.io/rdoc/RI_md.html

[character forward]:  rdoc-ref:@C-f+or+-E2-86-92-3A+Character+Forward
[character backward]: rdoc-ref:@C-b+or+-E2-86-90-3A+Character+Backward
[word forward]:       rdoc-ref:@M-f-3A+Word+Forward
[word backward]:      rdoc-ref:@M-b-3A+Word+Backward
[beginning of line]:  rdoc-ref:@C-a-3A+Beginning+of+Line
[end of line]:        rdoc-ref:@C-e-3A+End+of+Line
[clear screen]:       rdoc-ref:@C-l-3A+Clear+Screen
[clear display]:      rdoc-ref:@M-C-l-3A+Clear+Display

[accept line]:    rdoc-ref:@Enter-3A+Accept+Line
[previous command]: rdoc-ref:@C-p+or+-E2-86-91-3A+Previous+Command
[next command]:     rdoc-ref:@C-n+or+-E2-86-93-3A+Next+Command
[reverse search]:   rdoc-ref:@C-r-3A+Reverse+Search

[insert character]:                          rdoc-ref:@Any+Printable+Character-3A+Insert+Character
[delete character forward]:                  rdoc-ref:@Delete-3A+Delete+Character+Forward
[delete character forward (non-empty line)]: rdoc-ref:@C-d-3A+Delete+Character+Forward+-28Non-Empty+Line-29
[delete character backward]:                 rdoc-ref:@Backspace-3A+Delete+Character+Backward
[transpose characters]:                      rdoc-ref:@C-t-3A+Transpose+Characters
[transpose words]:                           rdoc-ref:@M-t-3A+Transpose+Words
[upcase word]:                               rdoc-ref:@M-u-3A+Upcase+Word
[downcase word]:                             rdoc-ref:@M-l-3A+Downcase+Word
[capitalize word]:                           rdoc-ref:@M-c-3A+Capitalize+Word

[kill line forward]:  rdoc-ref:@C-k-3A+Kill+Line+Forward
[kill line backward]: rdoc-ref:@C-u-3A+Kill+Line+Backward
[kill word forward]:  rdoc-ref:@M-d-3A+Kill+Word+Forward
[kill word backward]: rdoc-ref:@C-w-3A+Kill+Word+Backward
[yank last kill]:     rdoc-ref:@C-y-3A+Yank+Last+Kill

[complete word]:    rdoc-ref:@Tab-3A+Complete+Word
[show completions]: rdoc-ref:@Tab+Tab-3A+Show+Completions
