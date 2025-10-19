# For Users

This page is for the user of a Reline application.

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
- [Repetition prefixes][repetition prefixes].
- [Certain other commands][other commands].

A Reline application may support:

- [Word completion][word completion] (if enabled).
- [Command history][command history] (if enabled).

## Reline in Ruby

Ruby itself includes these Reline applications:

- [irb][irb]: Interactive Ruby.
- [debug][debug]: Ruby debugger.
- [ri][ri]: Ruby information.

## In Brief

Each table in this section summarizes a group of related Reline commands:

- **Command:** the keys for the command.
- **Repetition?:** whether a [repetition prefix][repetition] may be given.
- **Undoable?:** whether the action may be [undone][undo].
- **Action:** the action to be taken.

Details for the commands are at the links.

[Moving the cursor][commands for moving the cursor]:

|            Command            | Repetition? | Undoable? | Action                  |
|:-----------------------------:|:-----------:|:-----:|-----------------------------|
|  <tt>C-f</tt> or <tt>→</tt>   |   Yes.      |  No.  | Move forward one character. |
|  <tt>C-b</tt> or <tt>←</tt>   |    Yes.     |  No.  |                             |
|         <tt>M-f</tt>          |    Yes.     |  No.  | Move forward one word.      |
|         <tt>M-b</tt>          |    Yes.     |  No.  | Move backward one word.     |
| <tt>C-a</tt> or <tt>Home</tt> |     No.     |  No.  | Move to beginning of line.  |
| <tt>C-e</tt> or <tt>End</tt>  |     No.     |  No.  | Move to end of line.        |
|         <tt>C-l</tt>          |     No.     |  No.  | Clear screen.               |
|        <tt>M-C-l</tt>         |     No.     |  No.  | Clear display.              |

[Manipulating history][commands for manipulating the history]:

|          Command           | Repetition? | Undoable? | Action                          |
|:--------------------------:|:-----------:|:---------:|---------------------------------|
|       <tt>Enter</tt>       |     No.     |    No.    | Accept line.                    |
| <tt>C-p</tt> or <tt>↑</tt> |    Yes.     |   Yes.    | Move to previous command.       |
| <tt>C-n</tt> or <tt>↓</tt> |    Yes.     |   Yes.    | Move to next command.           |
|        <tt>M-p</tt>        |     No.     |    No.    | Non-incremental reverse search. |
|        <tt>M-n</tt>        |     No.     |    No.    | Non-incremental forward search. |

[Changing text][commands for changing text]:

|         Command          | Repetition? | Undoable? | Action                                         |
|:------------------------:|:-------:|:---------:|----------------------------------------------------|
| Any printable character. |   No.   |   Yes.    | Insert character.                                  |
|       <tt>Del</tt>       |   No.   |   Yes.    | Delete character forward.                          |
|       <tt>C-d</tt>       |   No.   |   Yes.    | Delete character forward (only if line non-empty). |
|    <tt>Backspace</tt>    |  Yes.   |   Yes.    | Delete character backward.                         |
|       <tt>C-t</tt>       |   No.   |   Yes.    | Transpose characters.                              |
|       <tt>M-t</tt>       |  Yes.   |   Yes.    | Transpose words.                                   |
|       <tt>M-u</tt>       |  Yes.   |   Yes.    | Upcase word.                                       |
|       <tt>M-l</tt>       |  Yes.   |   Yes.    | Downcase word.                                     |
|       <tt>M-c</tt>       |   No.   |   Yes.    | Capitalize word.                                   |

[Killing and yanking][commands for killing and yanking]:

|   Command    | Repetition? | Undoable? | Action              |
|:------------:|:-----------:|:---------:|---------------------|
| <tt>C-k</tt> |     No.     |   Yes.    | Kill line forward.  |
| <tt>C-u</tt> |     No.     |   Yes.    | Kill line backward. |
| <tt>M-d</tt> |     No.     |   Yes.    | Kill word forward.  |
| <tt>C-w</tt> |     No.     |   Yes.    | Kill word backward. |
| <tt>C-y</tt> |     No.     |   Yes.    | Yank last kill.     |

[Word completion][commands for word completion]:

|   Command        | Repetition? | Undoable? | Action                     |
|:----------------:|:-----------:|:---------:|----------------------------|
|   <tt>Tab</tt>   |     No.     |   Yes.    | Complete word if possible. |
| <tt>Tab Tab</tt> |     No.     |    No.    | Show possible completions. |

[Other commands][other commands]:

|    Command     | Repetition? | Undoable? | Action                                 |
|:--------------:|:-----------:|:---------:|----------------------------------------|
|  <tt>Esc</tt>  |     No.     |    No.    | Meta prefix.                           |
|  <tt>C-_</tt>  |     No.     |    No.    | Undo.                                  |
|  <tt>C-d</tt>  |     No.     |    No.    | Exit application (only if line empty). |
| <tt>Enter</tt> |     No.     |    No.    | Exit application (only if line empty). |

## Reline Defaults

Note that this page describes the _default_ usages for Reline,
with both [command history][command history] and [word completion][word completion] enabled,
as in this simple "echo" program:

```
require 'reline'
require 'open-uri'

# Get words for completion.
words_url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/refs/heads/master/google-10000-english-usa-no-swears-long.txt'
words = []
URI.open(words_url) do |file|
  while !file.eof?
    words.push(file.readline.chomp)
  end
end
# Install completion proc.
Reline.completion_proc = proc { |word|
  words
}
# REPL (Read-Evaluate-Print Loop)
prompt = 'echo> '
history = true
while line = Reline.readline(prompt, history)
  line.chomp!
  exit 0 if line.empty?
  puts "You typed: '#{line}'."
end
```

Other console applications that use module Reline may have implemented different usages.

## About the Examples

Examples on this page are derived from the echo program above.

In an example where cursor position is important,
we use the character `'ˇ'` to denote its position, thus:

```
'abcˇdef' # Denotes 6-character string 'abcdef' with cursor between 'c' and 'd'.
```

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
- `Del` denotes the Delete key.
- `End` denotes the End key.
- `Enter` denotes the Enter key.
- `Esc` denotes the Escape key.
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

## Repetition

A command may be prefixed by an integer argument
that specifies the number of times the command is to be executed.

Some commands support repetition; others do not.
See the tables in [In Brief][in brief].

If repetition for the command is supported and a repetition value of `n` is given,
the command is executed `n` times.

It the repetition is for the command is not supported, the repetition prefix is ignored.

## Command-Line Editing

### Undo

The undo command (`C-_`) "undoes" the action of a previous command (if any)
on the _current_ command line;
nothing is ever undone in an already-entered line.

Some commands can be undone; others cannot.
See the tables in [In Brief][in brief].

#### Immediate Undo

When the undo command is given and the immediately preceding command is undoable,
that preceding command is undone.

#### "Fall-Through" Undo

When the undo command is given and the immediately preceding command is not undoable,
the undo command "falls through" to commands given earlier.
Reline searches backward through the most recent commands for the current line:

- When an undoable command is found, that command is undone, and the search ends.
- If no such command is found, the undo command is ignored.

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
that it uses for word completion.

In the example echo program, typing `prof` followed by `Tab`
lets the program do a partial word completion, adding `ess` to form `profess`.

The program can add the partial completion `ess`
because all the available words that begin with `prof` also begin with `profess`.

But it can't complete the word because there are multiple words that begin with `profess`.

If we add `o` and `Tab`, the program can add `r` to form the complete word `professor`,
because that's the only word that begins `professo`.

To see the completion possibilities, type `Tab` twice;
this example types `profess` followed by two `Tab`s:

```
echo> profess
profession     professional   professionals  professor
```

Word completion works on the last word in the line,
which may not be the only word;
this example types `differential equ` followed by two `Tab`s
to get the possible completions:

```ruby
echo> differential equ
equations    equilibrium  equipment    equivalent
```

### Command History

A Reline application may support command history.

An easy way to find out whether it does:
after entering one or more commands, press key `↑`:

- Yes, if you now see the most recently entered command; read on.
- No, if you see no change; this section does not apply.

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

### Commands for Moving the Cursor

#### `C-f` or `→`: Character Forward

- **Action:** Move the cursor forward one character.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at end-of-line.

#### `C-b` or `←`: Character Backward

- **Action:** Move the cursor backward one character.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at beginning-of-line.

#### `M-f`: Word Forward

- **Action:** Move the cursor forward one word.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:**

    - If the cursor is in a word, move to the end of that word;
    - Otherwise (cursor at a space, for example), move to the end of the next word on the right.

#### `M-b`: Word Backward

- **Action:** Move the cursor backward one word.
- **Repetition?:** [Yes][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:**

    - If the cursor is in a word, move to the beginning of that word.
    - Otherwise (cursor at a space, for example), move to the beginning of the next word on the left.

#### `C-a`: Beginning of Line

- **Action:**: Move the cursor to the beginning of the line.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at beginning-of-line.
- 
#### `C-e`: End of Line

- **Action:** Move the cursor to the end of the line.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at end-of-line.
- 
#### `C-l`: Clear Screen

- **Action:** Clear the screen, then redraw the current line,
  leaving the current line at the top of the screen.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].

#### `M-C-l`: Clear Display

- **Action:** Like `C-l`, but also clear the terminal’s scrollback buffer if possible.
- **Repetition?:** [No][repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].

### Commands for Changing Text

#### Any Printable Character: Insert Character

- **Action:** Insert the character at the cursor position. 
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:** Move the trailing string (if any) one character width to the right, to "open a gap";
  place the cursor immediately after the inserted character.

#### `C-d`: Delete Character Forward

- **Action:** Delete the character at the cursor.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at end-of-line: do nothing.
    - Otherwise, delete the character at the cursor,
      move the trailing string (if any) one character to the left, to "close the gap",
      and leave the cursor in place.

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

#### `C-y`: Yank

- **Action:**: Insert killed text at the cursor and place the cursor at the end of the inserted text.
- **Repetition?:** [No][repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**: Do nothing if the kill buffer is empty.

### Repetition Prefixes

#### `M-`_digit_: Repetition

### Commands for Manipulating the History

####  `Enter`: Accept Line

#### `C-p` or `↑`: Previous History

#### `C-n` or `↓`: Next History

#### `C-r`: Reverse Search History

#### `M-p`: Non-Incremental Reverse Search History

#### `M-n`: Non-Incremental Forward Search History

### Commands for Word Completion

#### `Tab`: Complete Word

#### `Tab Tab`: Show Completions

### Other Commands

#### `Esc`: Meta Prefix

#### `C-_`: Undo

#### `C-d': Exit Application

#### `Enter': Exit Application

[commands for moving the cursor]:        rdoc-ref:for_users.md@Commands+for+Moving+the+Cursor
[commands for manipulating the history]: rdoc-ref:for_users.md@Commands+for+Manipulating+the+History
[commands for changing text]:            rdoc-ref:for_users.md@Commands+for+Changing+Text
[commands for killing and yanking]:      rdoc-ref:for_users.md@Commands+for+Killing+and+Yanking
[repetition prefixes]:                   rdoc-ref:for_users.md@Repetition+Prefixes
[commands for word completion]:          rdoc-ref:for_users.md@Commands+for+Word+Completion
[other commands]:                        rdoc-ref:for_users.md@Other+Commands

[in brief]:                              rdoc-ref:for_users.md@In+Brief
[reline defaults]:                       rdoc-ref:for_users.md@Reline+Defaults
[undo]:                                  rdoc-ref:for_users.md@Undo
[immediate undo]:                        rdoc-ref:for_users.md@Immediate+Undo
[fall-through undo]:                     rdoc-ref:for_users.md@22Fall-Through-22+Undo
[repetition]:                            rdoc-ref:for_users.md@Repetition
[command-line editing]:                  rdoc-ref:for_users.md@Command-Line+Editing
[command history]:                       rdoc-ref:for_users.md@Command+History
[word completion]:                       rdoc-ref:for_users.md@Word+Completion

[console application]: https://en.wikipedia.org/wiki/Console_application
[debug]:               https://github.com/ruby/debug
[irb]:                 https://ruby.github.io/irb/index.html
[repl]:                https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop
[ri]:                  https://ruby.github.io/rdoc/RI_md.html
