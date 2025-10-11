# For Users

This page is for the user of a console application that uses module Reline.
For other usages, see [Your Reline][your reline].

## In Brief

Each table in this section summarizes some Reline commands:

- *Command*: the keys for the command.
- *Repeat?*: whether a repeat count may be given;
  see [Specifying Numeric Arguments][specifying numeric arguments].
- *Undo?*: whether the action may be undone.
- *Action*: the action to be taken.

[Moving the cursor][commands for  the cursor]:

|    Command     | Repeat? | Undo? | Action                       |
|:--------------:|:-------:|:-----:|------------------------------|
|  <tt>C-f</tt>  | Yes.    |  No.  | Move forward one character.  |
|  <tt>C-b</tt>  |  Yes.   |  No.  | Move backward one character. |
|  <tt>M-f</tt>  |  Yes.   |  No.  | Move forward one word.       |
|  <tt>M-b</tt>  |  Yes.   |  No.  | Move backward one word.      |
|  <tt>C-a</tt>  |   No.   |  No.  | Move to beginning of line.   |
|  <tt>C-e</tt>  |   No.   |  No.  | Move to end of line.         |
|  <tt>C-l</tt>  |   No.   |  No.  | Clear screen.                |
| <tt>M-C-l</tt> |   No.   |  No.  | Clear display.               |

[Manipulating history][commands for manipulating the history]:

|    Command     | Repeat? | Undo? | Action                          |
|:--------------:|:-------:|:-----:|---------------------------------|
| <tt>Enter</tt> |   No.   |  No.  | Accept the line.                |
|  <tt>C-p</tt>  |  Yes.   | Yes.  | Move to previous command.       |
|  <tt>C-n</tt>  |  Yes.   | Yes.  | Move to next command.           |
|  <tt>C-r</tt>  |   No.   |  No.  | Reverse search of history.      |
|  <tt>M-p</tt>  |   No.   |  No.  | Non-incremental reverse search. |
|  <tt>M-n</tt>  |   No.   |  No.  | Non-incremental forward search. |

[Changing text][commands for changing text]:

|         Command          | Repeat? | Undo? | Action                                        |
|:------------------------:|:-------:|:-----:|-----------------------------------------------|
|       <tt>C-d</tt>       |   No.   | Yes.  | Delete character forward (if line non-empty). |
|       <tt>C-d</tt>       |   No.   |  No.  | Exit application (if line empty).             |
|     <tt>Rubout</tt>      |  Yes.   | Yes.  | Delete character backward.                    |
| Any printable character. |   No.   | Yes.  | Insert the character.                         |
|       <tt>C-t</tt>       |   No.   | Yes.  | Transpose characters.                         |
|       <tt>M-t</tt>       |  Yes.   | Yes.  | Transpose words.                              |
|       <tt>M-u</tt>       |  Yes.   | Yes.  | Upcase word.                                  |
|       <tt>M-l</tt>       |  Yes.   | Yes.  | Downcase word.                                |
|       <tt>M-c</tt>       |   No.   | Yes.  | Capitalize word.                              |

[Killing and yanking][commands for killing and yanking]:

|    Command     | Repeat? | Undo? | Action              |
|:--------------:|:-------:|:-----:|---------------------|
| <tt>C-k</tt>   |   No.   | Yes.  | Kill line forward.  |
|  <tt>C-u</tt>  |  No.    |       | Kill line backward. |
|  <tt>M-d</tt>  |   No.   | Yes.  | Kill word forward.  |
|  <tt>C-w</tt>  |   No.   | Yes.  | Kill word backward. |
|  <tt>C-y</tt>  |   No.   | Yes.  | Yank last kill.     |

[Word completion][commands for word completion]:

|   Command        | Repeat? | Undo? | Action                     |
|:----------------:|:-------:|:-----:|----------------------------|
|   <tt>Tab</tt>   |   No.   | Yes.  | Complete word if possible. |
| <tt>Tab Tab</tt> |   No.   | No.   | Show possible completions. |

[Other commands][other commands]:

|    Command    | Repeat? | Undo? | Action       |
|:-------------:|:-------:|:-----:|--------------|
| <tt>Esc</tt>  |   No.   |  No.  | Meta prefix. |
| <tt>C-_</tt>  |   No.   |  No.  |       Undo.  |

## Reline Defaults

Note that this page describes the _default_ usages for Reline,
with [command history][command history] and [command completion][command completion] enabled,
as in this simple "echo" program:

```
require 'reline'
require 'open-uri'

# Get words for completion.
words_url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/refs/heads/master/google-10000-english.txt'
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
- [Numeric arguments][specifying numeric arguments] for certain commands (to specify repetition).
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

[Arrow Keys][arrow keys]:

- `←` denotes the left-arrow key.
- `→` denotes the right-arrow key.
- `↑` denotes the up-arrow key.
- `↓` denotes the down-arrow key.
  
Other Keys

- `Alt` denotes the [Alt key][alt key]
- `Bsp` denotes the [Backspace key][backspace key]
- `Ctrl` denotes the [Control key][control key]
- `Del` denotes the [Delete key][delete key]
- `End` denotes the [End key][end key]
- `Ent` denotes the [Enter key][enter key]
- `Esc` denotes the [Escape key][escape key]
- `Home` denotes the [Home key][home key]
- `Spc` denotes the [Space bar][space bar]
- `Tab` denotes the [Tab key][tab key]

### Control Characters

`C-k` (read as "Control-k") denotes the input produced
when `Ctrl` is depressed (held down),
then the `k` key is then pressed, and both are released.

Almost any character can have a "control" version:
`C-a`, `C-{`, `C-]`, etc.

### Meta Characters

`M-k` (read as "Meta-k" or "Alt-k") denotes the input produced
when the `Alt` is depressed (held down),
then the `k` key is then pressed, and both are released.

Almost any character can have "meta" version:
`M-c`, `M->`, `M-#`, etc.

## Command-Line Editing

### Commands for Moving the Cursor

#### `C-a`: Beginning of Line

Move the cursor to the beginning of the line, if not already there.

#### `C-e`: End of Line

Move the cursor to the end of the line, if not already there.

#### `C-f`: Character Forward

Move the cursor forward one character, if not already at end-of-line.

#### `C-b`: Character Backward

Move the cursor backward one character, if not already at beginning-of-line.

#### `M-f`: Word Forward

Move the cursor forward one word, if not already at end-of-line:

- If cursor is in a word, move to the end of that word.
- If cursor is not in a word (at a space, for example), move to the end of the next word.

#### `M-b`: Word Backward

Move the cursor backward one word, if not already at beginning-of-line:

- If cursor is in a word, move to the beginning of that word.
- If cursor is not in a word (at a space, for example), move to the beginning of the next word on the left.

#### `C-l`: Clear Screen

Clear the screen, then redraw the current line, leaving the current line at the top of the screen;
if given a numeric argument, this refreshes the current line without clearing the screen.

#### `M-C-l`: Clear Display

Like 'C-l', but also clear the terminal’s scrollback buffer if possible.

### Commands for Manipulating the History

####  `Ent`: Accept Line

#### `C-p`: Previous History

#### `C-n`: Next History

#### `C-r`: Reverse Search History

#### `M-p`: Non-Incremental Reverse Search History

#### `M-n`: Non-Incremental Forward Search History

### Commands for Changing Text

#### `C-d`: Delete Character Forward or Exit Application

#### `Bsp`: Delete Character Backward

#### Printable Character

#### `C-t`: Transpose Characters

#### `M-t`: Transpose Words

#### `M-u`: Upcase Word

#### `M-l`: Downcase Word

#### `M-c`: Capitalize Word

### Commands for Killing and Yanking

#### `C-k`: Kill Line

#### `C-u`: Unix Discard Line

#### `M-d`: Kill Word

#### `C-w`: Unix Word Rubout

#### `C-y`: Yank

### Specifying Numeric Arguments

#### `M-`_digit_: Repetition

### Commands for Word Completion

#### `Tab`: Complete Word

#### `Tab Tab`: Show Completions

### Other Commands

#### `Esc`: Meta Prefix

#### `C-_` or `C-x C-u`: Undo


--------------------------------

## Reline Basics

Reline lets you edit typed command-line text.

### Cursor-Movement Commands

Character-by-character:

- `←` or `C-b`: backward one character.
- `→` or `C-f`: forward one character.

Word-by-word:

- `M-b`: backward to the beginning of a word.
- `M-f`: forward to the end of a word.

Whole line:

- `Home` or `C-a`: backward to the beginning of the line.
- `End` or `C-e`: forward to the end of the line.

Clear screen:

- 'C-l': Clear the screen, then redraw the current line, leaving the current line at the top of the screen.
  If given a numeric argument, this refreshes the current line without clearing the screen.
- 'M-C-l': Like 'C-l', but if possible also clear the terminal’s scrollback buffer. 

### Commands for Changing Text

Character deletion commands:

- `Del`: remove the character to the right the cursor if there is one.
- `C-d`: remove the character to the right the cursor if there is one.
  Note: if the command-line is empty, exit the application.
- `Bsp` or 'Rubout': remove the character to the left the cursor.

If a character is removed, existing characters to the right of the cursor are move leftward
to "close the gap."

Text insertion commands:

- Any printable character: insert the character at the cursor;
  existing characters to the right of the cursor are move rightward to "make room."

Transposing commands:

- 'C-t': transpose characters.
- 'M-t': transpose words.

Casing commands:

- 'M-u': upcase word.
- 'M-l': downcase word.
- 'M-c': capitalize word.
- 
### Other Commands

- `C-_`: undo the last editing command;
  may be repeated until the original (unedited) line is restored.
- `C-l`: clear the screen and reprint the current line at the top.

TODO: C-q;  C-v;  C-t;  C-_;  C-x C-u;  C-@;  C-x C-x;  C-];

## Killing and Yanking

_Killing_ means deleting text from the current line
and saving it for potential later use.
Killed text is pushed onto the _kill ring_
(a last-in, first-out [stack][stack]).

_Yanking_ means inserting previously-killed text into the current line.
Yanked text is popped from the kill ring.

For a kill command that is preceded by another kill command,
the killed text is appended to the text already at the top of the kill ring.
Thus, any number of consecutive kills save text as one string.

For a kill command that is _not_ preceded by another kill command,
the killed text is pushed onto the kill ring as a new entry.

The kill ring is not line specific;
text killed from a the current line is available for yanking into a new, later, current line.

### Kill Commands

Each kill command pushes the removed text onto the kill ring.

Kill forward; the cursor does not move:

- `C-k`: Kill from the cursor position to the end of the line.
- `M-d`: Kill from the cursor to the end of the current word,
  or, if between words, to the end of the next word;
  word boundaries are the same as those used by M-f.

Kill backward; the cursor moves leftward to "close the gap":

- `M-Del`: Kill from the cursor to the start of the current word,
  or, if between words, to the start of the previous word;
  word boundaries are the same as those used by M-b.
- `C-w`: Kill from the cursor to the previous whitespace;
  this is different from `M-Del` because the word boundaries are different.

TODO: C-x Rubout;  C-u;  M-y;

### Yank Commands

Each yank command pops text from the kill ring
and inserts it at the cursor;
the cursor is moved forward to the end of the inserted text.

- `C-y`: Yank the most recently killed text at the cursor.
- `M-y`: Rotate the kill ring, and yank from the new top.
  Effective only if the immediately preceding command was `C-y` or another `M-y`;
  otherwise, does nothing.

## Keyboard Macros

TODO: C-x (;  C-x );  C-x e;

## Miscellaneous Commands

TODO:  C-x C-r;
TODO:  M-A;  M-r;  M-~;  M-C-];  M-#;  M-x;  M-C-j

## Quantifiers

Some Reline commands accept quantifiers.

A quantifier is a positive integer repeat count `n`
that tells Reline to execute the command `n` times.

The quantifier precedes the command,
and is typed as numeric characters in range `('0'..'9')` while holding down the `Alt` key.

Examples:

- `M-4` `←` moves the cursor four characters to the left.
- `M-1` `M-4` `←` moves the cursor fourteen characters to the left.

TODO:  M-0;  

## Command History

A Reline application may support command history.

An easy way to find out whether it does is (after entering one or more commands) pressing key `↑`:

- Yes, if you now see the most recently entered command; read on.
- No, if you see no change; this section does not apply.

You can browse the history:

- `↑`: scroll upward in history (if not already at the earliest history).
- `↓`: scroll downward in history (if not already at the current line).

You can search the history using these commands:

- `C-r`: Initiate reverse search.
- `C-g` or `C-j`: Abort search.

To see history searching in action,
begin an [IRB][irb] session:

```
$ irb
'xyz'
# => "xyz"
'xy'
# => "xy"
'x'
# => "x"
```

In the table below:

- Each input character is incremental (no intervening characters)
  and is all on one editing line (does not generate a newline).
- Each result (still on that same line) is the immediate effect of that input.

|    Input     | Result                                | Details                             |
|:------------:|---------------------------------------|-------------------------------------|
| <tt>C-r</tt> | <tt>(reverse-i-search)`':</tt>        | New backward search.                |
| <tt>'x'</tt> | <tt>(reverse-i-search)`x''x'</tt>     | First command matching <tt>'x'</tt> |
| <tt>'y'</tt> | <tt>(reverse-i-search)`xy''xy'</tt>   | First command matching <tt>'y'</tt> |
| <tt>'z'</tt> | <tt>(reverse-i-search)`xyz''xyz'</tt> | First command matching <tt>'z'</tt> |
| <tt>C-j</tt> | <tt>'xyz'</tt>                        | Search aborted.                     |
| <tt>C-r</tt> | <tt>(reverse-i-search)`':</tt>        | New backward search.                |
| <tt>'y'</tt> | <tt>(reverse-i-search)`y''xy'</tt>    | First command matching <tt>'y'</tt> |
| <tt>Ent</tt> | <tt>'xy'</tt>                         | Command <tt>'xy'</tt> ready.        |

In the last instance, command `xy` is displayed on the edit line,
and is ready for execution (via `Ent`),
or for editing (via cursor movement, insertion, deletion, killing, yanking).

TODO: C-p;  C-n;  C-s;  C-o;
TODO: M->;  M-<;  M-p;  M-n;  M-C-y;  M-.;  M-_;  M-Tab;  M-t;  M-u;  M-l;  M-c;  

## Command Completion

A Reline application may support command completion,
which is implemented as responses to the `Tab` command,
by providing a list of command words.

Suppose an application just echoes whatever is typed to its prompt:

```
$ruby
echo> Hi!
You typed: 'Hi!'.
```

And suppose further that it has these command words:

```
['foo_foo', 'foo_bar', 'foo_baz', 'qux']
```

Then typing a single character `'q'` does not do much; we just see the one typed character:

```
echo> q
```

Pressing `Tab` requests command completion; we see the complete word:

```
echo> qux
```

That's because the only possible command word beginning with `'q'` is `'qux'`.
Then typing `'f'` does not do much; we just see the one character typed:

Adding `Ent` executes the command:

```
echo> qux
You typed: 'qux'.
echo>  
```

Typing the single character `'f'`, as before, does not do much:
```
echo> f
```

Pressing `Tab`, as before, requests command completion.
Because there are multiple command words starting with `'f'`, Reline cannot complete the command;
but because all command words starting with `'f'` also start with `'foo_'`,
Reline can partially complete the command:

```
echo> foo_
```

Pressing `Tab` a second time requests possible completions:

```
echo> foo_               
foo_bar foo_baz foo_foo
```

Now typing `'f'`, `Tab`, and `Ent` completes and enters the command:

```
echo> foo_foo
You typed: 'foo_foo'.
echo>     
```

Note that when the command line is empty, or when the typing so far does not match any command word,
`Tab` has no effect.

TODO:  M-?;  M-*;

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
    ```

[commands for moving the cursor]:        rdoc-ref:for_users.md@Commands+for+Moving+the+Cursor
[commands for manipulating the history]: rdoc-ref:for_users.md@Commands+for+Manipulating+the+History
[commands for changing text]:            rdoc-ref:for_users.md@Commands+for+Changing+Text
[commands for killing and yanking]:      rdoc-ref:for_users.md@Commands+for+Killing+and+Yanking
[specifying numeric arguments]:          rdoc-ref:for_users.md@Specifying+Numeric+Arguments
[commands for word completion]:          rdoc-ref:for_users.md@Commands+for+Word+Completion
[other commands]:                        rdoc-ref:for_users.md@Other+Commands

[alt key]: https://en.wikipedia.org/wiki/Alt_key
[ansi escape codes]: https://en.wikipedia.org/wiki/ANSI_escape_code
[arrow keys]: https://en.wikipedia.org/wiki/Arrow_keys
[backspace key]: https://en.wikipedia.org/wiki/Backspace
[command completion]: rdoc-ref:for_users.md@Command+Completion
[command history]: rdoc-ref:for_users.md@Command+History
[console application]: https://en.wikipedia.org/wiki/Console_application
[control key]: https://en.wikipedia.org/wiki/Control_key
[debug]: https://github.com/ruby/debug
[delete key]: https://en.wikipedia.org/wiki/Delete_key
[directives]: rdoc-ref:for_users.md@Directives
[editing-mode]: rdoc-ref:for_users.md@editing-mode
[emacs-mode-string]: rdoc-ref:for_users.md@emacs-mode-string
[end key]: https://en.wikipedia.org/wiki/End_key
[enter key]: https://en.wikipedia.org/wiki/Enter_key
[escape key]: https://en.wikipedia.org/wiki/Esc_key
[home key]: https://en.wikipedia.org/wiki/Home_key
[irb]: https://ruby.github.io/irb/index.html
[key bindings]: rdoc-ref:for_users.md@Key+Bindings
[macro]: https://en.wikipedia.org/wiki/Macro_(computer_science)
[mode strings]: rdoc-ref:for_users.md@Mode+Strings
[repl]: https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop
[ri]: https://ruby.github.io/rdoc/RI_md.html
[show-mode-in-prompt]: rdoc-ref:for_users.md@show-mode-in-prompt
[space bar]: https://en.wikipedia.org/wiki/Space_bar
[stack]: https://en.wikipedia.org/wiki/Stack_(abstract_data_type)
[tab key]: https://en.wikipedia.org/wiki/Tab_key
[variables]: rdoc-ref:for_users.md@Variables
[vi-cmd-mode-string]: rdoc-ref:for_users.md@vi-cmd-mode-string
[vi-ins-mode-string]: rdoc-ref:for_users.md@vi-ins-mode-string
[your reline]: rdoc-ref:README.md@Your+Reline

[TODO]

- Resolve all C- and M- from Gnu doc.
- Doc which commands accept arguments.
- Multi-line editing.
