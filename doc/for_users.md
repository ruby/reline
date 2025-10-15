# For Users

This page is for the user of a console application that uses module Reline.
For other usages, see [Your Reline][your reline].

## In Brief

Each table in this section summarizes a group of related Reline commands:

- **Command:** the keys for the command.
- **Repetition?:** whether a [repetition prefix][about repetition] may be given.
- **Undoable?:** whether the action may be [undone][undo command].
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
|       <tt>Enter</tt>       |     No.     |    No.    | Enter line.                     |
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
with both [command history][command history] and [command completion][command completion] enabled,
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

- [Command completion][command completion] (if enabled).
- [Command history][command history] (if enabled).

## Reline in Ruby

Ruby itself uses Reline in these applications:

- [irb][irb]: Interactive Ruby.
- [debug][debug]: Ruby debugger.
- [ri][ri]: Ruby information.

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
and saving it for potential later use (by _yanking_).

_Yanking_ means inserting previously-killed text into the current line.
Yanked text is, depending on the command used, copied from or popped from the kill ring.

Killed text is put onto the _kill ring_
(a last-in, first-out [stack][stack]):

- For a kill command that is preceded by another kill command,
  the killed text is appended to the entry already at the top of the kill ring.
  Thus, any number of consecutive kills save killed text as a single string.
- For a kill command that is _not_ preceded by another kill command,
  the killed text is pushed onto the kill ring as a new entry.

The kill ring is not associated with particular command lines;
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

### Commands for Moving the Cursor

#### `C-f` or `→`: Character Forward

- **Action:** Move the cursor forward one character.
- **Repetition?:** [Yes][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at end-of-line.

#### `C-b` or `←`: Character Backward

- **Action:** Move the cursor backward one character.
- **Repetition?:** [Yes][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at beginning-of-line.

#### `M-f`: Word Forward

- **Action:** Move the cursor forward one word.
- **Repetition?:** [Yes][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:**

    - If the cursor is in a word, move to the end of that word;
    - Otherwise (cursor at a space, for example), move to the end of the next word on the right.

#### `M-b`: Word Backward

- **Action:** Move the cursor backward one word.
- **Repetition?:** [Yes][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:**

    - If the cursor is in a word, move to the beginning of that word.
    - Otherwise (cursor at a space, for example), move to the beginning of the next word on the left.

#### `C-a`: Beginning of Line

- **Action:**: Move the cursor to the beginning of the line.
- **Repetition?:** [No][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at beginning-of-line.
- 
#### `C-e`: End of Line

- **Action:** Move the cursor to the end of the line.
- **Repetition?:** [No][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].
- **Details:** Do nothing if already at end-of-line.
- 
#### `C-l`: Clear Screen

- **Action:** Clear the screen, then redraw the current line,
  leaving the current line at the top of the screen.
- **Repetition?:** [No][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].

#### `M-C-l`: Clear Display

- **Action:** Like `C-l`, but also clear the terminal’s scrollback buffer if possible.
- **Repetition?:** [No][about repetition].
- **Undoable?:** No; attempt [fall-through undo][fall-through undo].

### Commands for Changing Text

#### Any Printable Character: Insert Character

- **Action:** Insert the character at the cursor position. 
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:** Move the trailing string (if any) one character width to the right, to "open a gap";
  place the cursor immediately after the inserted character.

#### `C-d`: Delete Character Forward

- **Action:** Delete the character at the cursor.
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at end-of-line: do nothing.
    - Otherwise, delete the character at the cursor,
      move the trailing string (if any) one character to the left, to "close the gap",
      and leave the cursor in place.

#### `Backspace`: Delete Character Backward

- **Action:** Delete the character before the cursor.
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at beginning-of-line: do nothing.
    - Otherwise, move the cursor and the trailing string (if any) one character to the left,
      to "close the gap."

#### `C-t`: Transpose Characters

- **Action:** Transpose two characters (by exchanging their positions).
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**

    - If at beginning-of-line, or if there is only one character, do nothing.
    - Otherwise, if at end-of-line, transpose the last two characters; leave the cursor in place.
    - Otherwise, transpose the single characters before and after the cursor
      and move the cursor to the end of the transposed pair.

#### `M-t`: Transpose Words

- **Action:**: Transpose two words (by exchanging their positions).
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at the beginning-of-line, or if in the first word, or if there is only one word, do nothing.
    - If in a non-first word, or at the beginning or end of the last word,
      transpose that word and the preceding word and move the cursor to the end of the word pair.
    - If at the end of a non-last word,
      transpose that word and the following word and move the cursor to the end of the word pair.
  
#### `M-u`: Upcase Word

- **Action:**: Change word to uppercase.
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, upcase the entire word and move cursor to the end of that word.
    - If in a word, upcase the rightward part of the word and move cursor to the end of that word.
    - If at the end of a word, upcase the next word and move cursor to the end of that word.

#### `M-l`: Downcase Word

- **Action:**: Change word to lowercase.
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, downcase the entire word and move cursor to the end of that word.
    - If in a word, downcase the rightward part of the word and move cursor to the end of that word.
    - If at the end of a word, downcase the next word and move cursor to the end of that word.

#### `M-c`: Capitalize Word

- **Action:**: Capitalize word.
- **Repetition?:** [No][about repetition].
- **Undoable?:** Yes; execute [immediate undo].
- **Details:**:

    - If at end-of-line, do nothing.
    - If at the beginning of a word, upcase its first character and move cursor to the end of that word.
    - If in a word, upcase the next character and move cursor to the end of that word.
    - If at the end of a word, upcase the first character of the next word and move cursor to the end of that word.

### Commands for Killing and Yanking

#### `C-k`: Kill Line

#### `C-u`: Unix Discard Line

#### `M-d`: Kill Word

#### `C-w`: Unix Word Rubout

#### `C-y`: Yank

### Repetition Prefixes

#### `M-`_digit_: Repetition

### Commands for Manipulating the History

A Reline application may support command history.

An easy way to find out whether it does is (after entering one or more commands) pressing key `↑`:

- Yes, if you now see the most recently entered command; read on.
- No, if you see no change; this section does not apply.

####  `Enter`: Accept Line

#### `C-p` or `↑`: Previous History

#### `C-n` or `↓`: Next History

#### `C-r`: Reverse Search History

#### `M-p`: Non-Incremental Reverse Search History

#### `M-n`: Non-Incremental Forward Search History

#### History in Action

To see history searching in action,
begin an [IRB][irb] session:

```
$ irb
'xyz'
# => "xyz"
'xy'
# => "xy"
'x'
`# => "x"
```

In the table below:

- Each command is incremental (no intervening characters)
  and is all on one editing line (does not generate a newline).
- Each result (still on that same line) is the immediate effect of that input.

|    Command     | Result                                | Details                             |
|:--------------:|---------------------------------------|-------------------------------------|
|  <tt>C-r</tt>  | <tt>(reverse-i-search)`':</tt>        | New backward search.                |
|  <tt>'x'</tt>  | <tt>(reverse-i-search)`x''x'</tt>     | First command matching <tt>'x'</tt> |
|  <tt>'y'</tt>  | <tt>(reverse-i-search)`xy''xy'</tt>   | First command matching <tt>'y'</tt> |
|  <tt>'z'</tt>  | <tt>(reverse-i-search)`xyz''xyz'</tt> | First command matching <tt>'z'</tt> |
|  <tt>C-j</tt>  | <tt>'xyz'</tt>                        | Search aborted.                     |
|  <tt>C-r</tt>  | <tt>(reverse-i-search)`':</tt>        | New backward search.                |
|  <tt>'y'</tt>  | <tt>(reverse-i-search)`y''xy'</tt>    | First command matching <tt>'y'</tt> |
| <tt>Enter</tt> | <tt>'xy'</tt>                         | Command <tt>'xy'</tt> ready.        |

In the last instance, command `xy` is displayed on the edit line,
and is ready for execution (via `Enter`),
or for editing (via cursor movement, insertion, deletion, killing, yanking).

### Commands for Word Completion

#### `Tab`: Complete Word

#### `Tab Tab`: Show Completions

### Other Commands

#### `Esc`: Meta Prefix

#### `C-_`: Undo

#### `C-d': Exit Application

#### `Enter': Exit Application

## Initialization File

A Reline application has default key bindings and variable definitions,
as determined by the application itself.

You can customize the application's behavior by specifying key bindings and variable definitions
in an _initialization file_.
The initialization file may define:

- [Key Bindings][key bindings]: Definitions relating keys to variables.
- [Variables][variables]:
- [Directives][directives].

When a Reline application starts, it reads a user-provided initialization file,
whose path is determined thus:

- The path specified by `ENV['INPUTRC']` if defined.
- Otherwise, `~/.inputrc`, if that file exists.
- Otherwise, if `ENV['XDG_CONFIG_HOME']` is defined (call its value `path`),
  `File.join(path, 'readline/inputrc')`.
- Otherwise, `'~/.config/readline/inputrc'`.
- Otherwise, no initialization file is read.

### Variables

The initialization file may re-define certain variables.

#### `completion-ignore-case`

If set to `'on'`, Reline performs case-insensitive
filename matching and completion.

The default setting is `'off'`.

#### `convert-meta`

If set to `'on'`, affects 8-bit characters that have their high bits set
(i.e., characters whose values in range `128..255`).
Reline converts each such character by clearing the high bit
(which puts the character in range `0..127`)
and prefixing `Esc`.

The default value is `'on'`, but Reline sets it to `'off'`
if the locale contains characters whose encodings may include bytes with the eighth bit set.

#### `disable-completion`

If set to `'on'`, Reline inhibits word completion.
Completion characters (`Tab`, `M-?`, and `M-*`) lose their usual meanings,
and are inserted directly into the line.

The default is `'off'`.

#### `editing-mode`

If set to `'emacs'`, the default key bindings are similar to Emacs;
If set to `'vi'`, the default key bindings are similar to Vi.

The default is `'emacs'`.

#### `emacs-mode-string`

Specifies the mode string for Emacs mode;
see [Mode Strings][mode strings].

The default is `'@'`.

#### `enable-bracketed-paste`

When set to `'On'`, Reline is in _bracketed-paste_ mode,
which means that it inserts each paste or yank
into the editing buffer as a single string of characters,
instead of treating each character as if it had been read from the keyboard.
This prevents Reline from executing any editing commands
bound to key sequences appearing in the pasted text.

The default is `'on'`.

#### `history-size`

Set the maximum number of entries saved in the history list:

- Zero: existing history entries are deleted and no new entries are saved.
- Negative: the number of history entries is not limited.
- Non-numeric value: the maximum number of history entries is set to 500.

Default value is `'-1'`

#### `isearch-terminators`

Sets the strings of characters that terminate an incremental search
without subsequently executing the character as a command.

Default: `Esc` and `C-j`.

#### `keymap`

Sets the keymap for key binding commands.
Values are:

- `'emacs'` (aliased as `'emacs-standard'`).
- `'emacs-ctlx'`.
- `'emacs-meta'`.
- `'vi-command'` (aliased as `'vi'` and `'vi-move'`).
- `'vi-insert'`.

Default is `'emacs'`.
The value of variable [editing-mode][editing-mode]
also affects the default keymap.

#### `keyseq-timeout`

Specifies the time (in milliseconds) that Reline will wait for further input
when reading an ambiguous key sequence
(i.e., one that can form a complete key sequence using the input read so far,
or can take additional input to complete a longer key sequence).

If Reline doesn’t receive further input within the timeout,
it uses the shorter but complete key sequence.

If this variable is set to a value less than or equal to zero, or to a non-numeric value,
Reline waits until another key is pressed to decide which key sequence to complete.

The default `'500'`.

#### `show-all-if-ambiguous`

If set to `'on'`, input that has more than one possible completion
cause the completions to be listed immediately (instead of ringing the bell).

The default is `'off'`.

#### `show-mode-in-prompt`

If set to `'on'`, prefixed the mode string to the displayed prompt;
see [Mode Strings][mode strings].

The default is `'off'`.

#### `vi-cmd-mode-string`

Specifies the mode string for Vi command mode;
see [Mode Strings][mode strings].

The default is ‘(cmd)’.

#### `vi-ins-mode-string`

Specifies the mode string for Vi insertion mode;
see [Mode Strings][mode strings].

The default is ‘(ins)’.

#### Mode Strings

A _mode string_ is a string that is to be displayed immediately before the prompt string
when variable [show-mode-in-prompt][show-mode-in-prompt] is set to `'on'`.

There are three mode strings:

- Emacs mode string:
  the value of variable [emacs-mode-string][emacs-mode-string];
  effective when variable [editing-mode][editing-mode] is `'emacs'`.
  Default value is `'@'`.
- Vi command mode string:
  the value of variable [vi-cmd-mode-string][vi-cmd-mode-string];
  effective when variable [editing-mode][editing-mode] is `'vi'`
  and the editing is in command mode.
  Default value is `'(cmd)'`.
- Vi insertion mode string:
  the value of variable [vi-ins-mode-string][vi-ins-mode-string];
  effective when variable [editing-mode][editing-mode] is `'vi'`
  and the editing is in insertion mode.
  Default value is `'(ins)'`.

The mode string may include [ANSI escape codes][ansi escape codes]
which can affect the color (foreground and background) and font (bold, italic, etc.) of the display.
The ANSI escape codes must be preceded by escape `\1` and followed by escape `\2`.

Example (turns the mode string green):

```
"\1\e[32mabcd \e[0m\2"
```

### Key Bindings

In brief:

```
"\C-x\M-r":  "Ruby!"          # Key sequence bound to text.
"\C-x\M-c":  ed_clear_screen  # Key sequence bound to method.
Meta-l:      " | less"        # Key name bound to text.
Control-b:   ed_clear_screen  # Key name bound method.
```

A key or key sequence may be bound to:

- Text to be inserted when the key or key sequence is typed in:
  in effect a [macro][macro].
- A Reline method that is to be called when the key or key sequence is typed in:
  in effect an alias.

#### Key Sequences

You can bind a key sequence to text, defining a macro.
The key sequence specifies a sequence of one or more keys that are to be mapped
to text that is to be inserted when the sequence is typed as input.

This example binds a key sequence to the _macro_ text,
which means that in the application pressing `C-x` followed by `M-r` inserts the text  `'Ruby!'`:

```
"\C-x\M-r": "Ruby!"
```

Note that:

- The key sequence must be enclosed by double-quotes.
- The first key must be specified in an escaped notation
  (not just a regular character).
- There may be no space between the two key specifications.
- The key sequence must be immediately followed by a colon (`':'`); no intervening whitespace.
- The colon may be separated from the following text by whitespace.
- The text must be enclosed by double-quotes.


More examples:

```
# Meta characters and control characters.
"\M-x":     "Alt-x"          # Single meta character.
"\C-a":     "Ctrl-a"         # Single control character.
"\C-x\C-y": "Ctrl-x, Ctrl-y" # Multiple keys.
"\C-xm":    "Ctrl-x, m"      # Control key followed by regular character.

# Escaped regular characters.
"\\":       "Backslash"      # Backslash character.
"\"":       "Double-quote"   # Double-quote character.
"\'":       "Single-quote"   # Single-quote character.

# Special escapes for certain control characters.
"\a":       "Bell"
# (Probably not a good idea to interfere with these.)
# "\b":       "Backspace"
# "\d":       "Delete"
# "\f":       "Form-feed"
# "\n":       "Newline"
# "\r":       "Carriage return"
# "\t":       "Horizontal tab"
# "\v":       "Vertical tab"

# Other forms for the key sequence.
"\001": "Ctrl-a" # Octal number; begins with "\0".
"\x02": "Ctrl-b" # Hexadecimal number; begins with "\x".
```

You can bind a key sequence to a Reline method,
so that the method is called when the key sequence is typed as input.
See [Methods](rdoc-ref:for_users.md@Methods).

This example binds a key sequence to the method `ed_clear_screen`,
which means that in the application pressing `Alt-x` clears the screen
and reprints the prompt at the top:

```
"\M-x": ed_clear_screen
```

This binding is the same as the default binding for `C-l`.
Note that this new binding would override the old one, if any, for that key,
but does not disturb other bindings (`C-l` is still bound to `ed_clear_screen`).

#### Key Names

You can bind a single key to text or a method using its _key name_
(instead of the key sequence notation):

```
Control-b: ed_clear_screen
Meta-L: " | less"
```

#### Methods

These are the methods available for binding by a key or key sequence:

- `ed_argument_digit(key)`
- `ed_beginning_of_history(key)`
- `ed_clear_screen(key)`
- `ed_delete_next_char(key, arg: 1)`
- `ed_delete_prev_char(key, arg: 1)`
- `ed_delete_prev_word(key)`
- `ed_digit(key)`
- `ed_end_of_history(key)`
- `ed_kill_line(key)`
- `ed_move_to_beg(key)`
- `ed_move_to_end(key)`
- `ed_newline(key)`
- `ed_next_char(key, arg: 1)`
- `ed_next_history(key, arg: 1)`
- `ed_prev_char(key, arg: 1)`
- `ed_prev_history(key, arg: 1)`
- `ed_prev_word(key)`
- `ed_search_next_history(key, arg: 1)`
- `ed_search_prev_history(key, arg: 1)`
- `ed_transpose_chars(key)`
- `ed_transpose_words(key)`
- `ed_unassigned(key) end # do nothing`
- `em_capitol_case(key)`
- `em_delete(key)`
- `em_delete_next_word(key)`
- `em_delete_or_list(key)`
- `em_delete_prev_char(key, arg: 1)`
- `em_exchange_mark(key)`
- `em_kill_line(key)`
- `em_kill_region(key)`
- `em_lower_case(key)`
- `em_next_word(key)`
- `em_set_mark(key)`
- `em_upper_case(key)`
- `em_yank(key)`
- `em_yank_pop(key)`
- `emacs_editing_mode(key)`
- `incremental_search_history(key)`
- `key_delete(key)`
- `key_newline(key)`
- `process_key(key, method_symbol)`
- `run_for_operators(key, method_symbol)`
- `search_next_char(key, arg, need_prev_char: false, inclusive: false)`
- `search_prev_char(key, arg, need_next_char = false)`
- `vi_add(key)`
- `vi_add_at_eol(key)`
- `vi_change_meta(key, arg: nil)`
- `vi_change_to_eol(key)`
- `vi_command_mode(key)`
- `vi_delete_meta(key, arg: nil)`
- `vi_delete_prev_char(key)`
- `vi_editing_mode(key)`
- `vi_end_big_word(key, arg: 1, inclusive: false)`
- `vi_end_word(key, arg: 1, inclusive: false)`
- `vi_first_print(key)`
- `vi_histedit(key)`
- `vi_insert(key)`
- `vi_insert_at_bol(key)`
- `vi_join_lines(key, arg: 1)`
- `vi_kill_line_prev(key)`
- `vi_list_or_eof(key)`
- `vi_next_big_word(key, arg: 1)`
- `vi_next_char(key, arg: 1, inclusive: false)`
- `vi_next_word(key, arg: 1)`
- `vi_paste_next(key, arg: 1)`
- `vi_paste_prev(key, arg: 1)`
- `vi_prev_big_word(key, arg: 1)`
- `vi_prev_char(key, arg: 1)`
- `vi_prev_word(key, arg: 1)`
- `vi_replace_char(key, arg: 1)`
- `vi_search_next(key)`
- `vi_search_prev(key)`
- `vi_to_column(key, arg: 0)`
- `vi_to_history_line(key)`
- `vi_to_next_char(key, arg: 1, inclusive: false)`
- `vi_to_prev_char(key, arg: 1)`
- `vi_yank(key, arg: nil)`
- `vi_zero(key)`




### Directives

#### `$if`, `$else`, and `$endif`

The initialization file may contain conditional directives,
each of which is an `$if/$endif` pair,
or an `$if/$else/$endif` triplet.

- In the `$if/$endif` form,
  the if-block consists of the lines between `$if` and `$endif`,
  and there is no else-block:

    ```
    $if <condition>
      # If-block
    #endif
    ```

- In the `$if/$else/$endif` form,
  the if-block consists of the lines between `$if` and `$else`,
  and the else-block consists of the lines between `$else` and `$endif`:

    ```
    $if <condition>
      # If-block
    $else
      # Else-block.
    #endif
    ```

The `$if` directive takes a single argument that expresses a condition.
If the condition evaluates to `true`,
the expressions in the if-block are evaluated;
if it evaluates to `false`,
the expressions in the else-block (if any) are evaluated.

The arguments:

- `'mode=emacs'`:
  evaluates to `true` if variable [editing-mode][editing-mode] is `'emacs'`,
  `false` otherwise.
- `'mode=vi'`:
  evaluates to `true` if variable [editing-mode][editing-mode] is `'vi'`,
  `false` otherwise.
- `'Ruby'` or `'Reline'`:
  evaluates to `true`.
- Anything else:
  evaluates to `false`.

Conditional directives may be nested.

#### $include

The `$include` directive takes a single argument,
which is the path to a file that is to be read and evaluated
as if it were part of the initialization file.

Pro tip: You can use the `$include` directive to override (in full or in part)
another initialization file:

    ```
    $include <filepath>
    # Assignments and directives that will override.
    # ...

[commands for moving the cursor]:        rdoc-ref:for_users.md@Commands+for+Moving+the+Cursor
[commands for manipulating the history]: rdoc-ref:for_users.md@Commands+for+Manipulating+the+History
[commands for changing text]:            rdoc-ref:for_users.md@Commands+for+Changing+Text
[commands for killing and yanking]:      rdoc-ref:for_users.md@Commands+for+Killing+and+Yanking
[repetition prefixes]:                   rdoc-ref:for_users.md@Repetition+Prefixes
[commands for word completion]:          rdoc-ref:for_users.md@Commands+for+Word+Completion
[other commands]:                        rdoc-ref:for_users.md@Other+Commands

[in brief]:                              rdoc-ref:for_users.md@In+Brief
[reline defaults]:                       rdoc-ref:for_users.md@Reline+Defaults
[immediate undo]:                        rdoc-ref:for_users.md@Immediate+Undo
[fall-through undo]:                     rdoc-ref:for_users.md@22Fall-Through-22+Undo
[repetition]:                            rdoc-ref:for_users.md@Repetition

[ansi escape codes]: https://en.wikipedia.org/wiki/ANSI_escape_code
[command completion]: rdoc-ref:for_users.md@Command+Completion
[command history]: rdoc-ref:for_users.md@Command+History
[console application]: https://en.wikipedia.org/wiki/Console_application
[debug]: https://github.com/ruby/debug
[directives]: rdoc-ref:for_users.md@Directives
[editing-mode]: rdoc-ref:for_users.md@editing-mode
[emacs-mode-string]: rdoc-ref:for_users.md@emacs-mode-string
[irb]: https://ruby.github.io/irb/index.html
[key bindings]: rdoc-ref:for_users.md@Key+Bindings
[macro]: https://en.wikipedia.org/wiki/Macro_(computer_science)
[mode strings]: rdoc-ref:for_users.md@Mode+Strings
[repl]: https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop
[ri]: https://ruby.github.io/rdoc/RI_md.html
[show-mode-in-prompt]: rdoc-ref:for_users.md@show-mode-in-prompt
[space bar]: https://en.wikipedia.org/wiki/Space_bar
[stack]: https://en.wikipedia.org/wiki/Stack_(abstract_data_type)
[variables]: rdoc-ref:for_users.md@Variables
[vi-cmd-mode-string]: rdoc-ref:for_users.md@vi-cmd-mode-string
[vi-ins-mode-string]: rdoc-ref:for_users.md@vi-ins-mode-string
[your reline]: rdoc-ref:README.md@Your+Reline

[TODO]

- Resolve all C- and M- from Gnu doc.
- Doc which commands accept arguments.
- Multi-line editing.
