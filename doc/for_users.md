# For Users

This page is for the user of a console application that uses module Reline.
For other usages, see [Your Reline](rdoc-ref:README.md@Your+Reline).

Note that this page describes the _default_ usages for Reline.
A console application that uses module Reline may have implemented different usages.

## Reline Application

A _Reline application_ is a Ruby
[console application](https://en.wikipedia.org/wiki/Console_application)
that uses module Reline.

Such an application typically implements
a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
(a read-evaluate-print loop)
that allows you to type a command, get a response,
type another command, get another response, and so on.

A Reline application allows editing a partly-entered command by:

- Moving the cursor within its text.
- Deleting text.
- Inserting text.
- "Killing" text (i.e., deleting and saving text).
- "Yanking" text (i.e., inserting previously killed text).

A Reline application may also support:

- [Command history](https://en.wikipedia.org/wiki/Command_history):
  a store of previously entered commands that may be retrieved, edited, and re-used.
- [Command completion](https://en.wikipedia.org/wiki/Command-line_completion):
  assistance in completing a partly-entered command,
  or in choosing among possible completions.
  
## Reline in Ruby

Ruby itself uses Reline in these:

- [irb](https://ruby.github.io/irb/index.html): Interactive Ruby.
- [debug](https://github.com/ruby/debug): Ruby debugger.
- [ri](https://ruby.github.io/rdoc/RI_md.html) Ruby information.

## Notations

### Keys

[Arrow Keys](https://en.wikipedia.org/wiki/Arrow_keys):

- `←` denotes the left-arrow key.
- `→` denotes the right-arrow key.
- `↑` denotes the up-arrow key.
- `↓` denotes the down-arrow key.
  
Other Keys

- `Alt` denotes the [Alt key](https://en.wikipedia.org/wiki/Alt_key).
- `Bsp` denotes the [Backspace key](https://en.wikipedia.org/wiki/Backspace).
- `Ctrl` denotes the [Control key](https://en.wikipedia.org/wiki/Control_key).
- `Del` denotes the [Delete key](https://en.wikipedia.org/wiki/Delete_key) .
- `End` denotes the [End key](https://en.wikipedia.org/wiki/End_key).
- `Ent` denotes the [Enter key](https://en.wikipedia.org/wiki/Enter_key).
- `Esc` denotes the [Escape key](https://en.wikipedia.org/wiki/Esc_key).
- `Home` denotes the [Home key](https://en.wikipedia.org/wiki/Home_key).
- `Spc` denotes the [Space bar](https://en.wikipedia.org/wiki/Space_bar).
- `Tab` denotes the [Tab key](https://en.wikipedia.org/wiki/Tab_key).

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

## The Basics

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

### Text-Deletion Commands

- `Del` or `C-d`: remove the character to the right the cursor
- `Bsp`: remove the character to the left the cursor.

In either case, existing characters to the right of the cursor are move leftward
to "close the gap."

### Text-Insertion Commands

- Any printable character: insert the character at the cursor;
  existing characters to the right of the cursor are move rightward to "make room."

### Other Commands

- `C-_`: undo the last editing command;
  may be repeated until the original (unedited) line is restored.
- `C-l`: clear the screen and reprint the current line at the top.

## Killing and Yanking

_Killing_ means deleting text from the current line
and saving it for potential later use.
Killed text is pushed onto the _kill ring_
(a last-in, first-out [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type))).

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

### Yank Commands

Each yank command pops text from the kill ring
and inserts it at the cursor;
the cursor is moved forward to the end of the inserted text.

- `C-y`: Yank the most recently killed text at the cursor.
- `M-y`: Rotate the kill ring, and yank from the new top.
  Effective only if the immediately preceding command was `C-y` or another `M-y`;
  otherwise, does nothing.

## Quantifiers

[TODO]

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
begin an [IRB](https://ruby.github.io/irb/index.html) session:

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

## Command Completion

[TODO]

## Initialization File

When a Reline application starts, it reads a user-provided initialization file,
whose path is determined thus:

- The path specified by `ENV['INPUTRC']` if defined.
- Otherwise, `~/.inputrc`, if that file exists.
- Otherwise, if `ENV['XDG_CONFIG_HOME']` is defined (call its value `path`),
  `File.join(path, 'readline/inputrc')`.
- Otherwise, `'~/.config/readline/inputrc'`.
- Otherwise, no initialization file is read.

The initialization file may contain _directives_, _bindings_, and _variables_.
  
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
  evaluates to `true` if variable [editing-mode](rdoc-ref:for_users.md@editing-mode) is `'emacs'`,
  `false` otherwise.
- `'mode=vi'`:
  evaluates to `true` if variable [editing-mode](rdoc-ref:for_users.md@editing-mode) is `'vi'`,
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


### Bindings

[TODO]

### Variables

### `completion-ignore-case`

If set to `'on'`, Reline performs case-insensitive
filename matching and completion.

The default setting is `'off'`.

### `convert-meta`

If set to `'on'`, affects 8-bit characters that have their high bits set
(i.e., characters whose values in range `128..255`).
Reline converts each such character by clearing the high bit
(which puts the character in range `0..127`)
and prefixing `Esc`.

The default value is `'on'`, but Reline sets it to `'off'`
if the locale contains characters whose encodings may include bytes with the eighth bit set.

### `disable-completion`

If set to `'on'`, Reline inhibits word completion.
Completion characters (`Tab`, `M-?`, and `M-*`) lose their usual meanings,
and are inserted directly into the line.

The default is `'off'`.

### `editing-mode`

If set to `'emacs'`, the default key bindings are similar to Emacs;
If set to `'vi'`, the default key bindings are similar to Vi.

The default is `'emacs'`.

### `emacs-mode-string`

Specifies the mode string for Emacs mode;
see [Mode Strings](rdoc-ref:for_users.md@Mode+Strings).

The default is `'@'`.

### `enable-bracketed-paste`

When set to `'On'`, Reline is in _bracketed-paste_ mode,
which means that it inserts each paste or yank
into the editing buffer as a single string of characters,
instead of treating each character as if it had been read from the keyboard.
This prevents Reline from executing any editing commands
bound to key sequences appearing in the pasted text.

The default is `'on'`.

### `history-size`

Set the maximum number of entries saved in the history list:

- Zero: existing history entries are deleted and no new entries are saved.
- Negative: the number of history entries is not limited.
- Non-numeric value: the maximum number of history entries is set to 500.

Default value is `'-1'`

### `isearch-terminators`

Sets the strings of characters that terminate an incremental search
without subsequently executing the character as a command.

Default: `Esc` and `C-j`.

### `keymap`

Sets the keymap for key binding commands.
Values are:

- `'emacs'` (aliased as `'emacs-standard'`).
- `'emacs-ctlx'`.
- `'emacs-meta'`.
- `'vi-command'` (aliased as `'vi'` and `'vi-move'`).
- `'vi-insert'`.

Default is `'emacs'`.
The value of variable [editing-mode](rdoc-ref:for_users.md@editing-mode)
also affects the default keymap.

### `keyseq-timeout`

Specifies the time (in milliseconds) that Reline will wait for further input
when reading an ambiguous key sequence
(i.e., one that can form a complete key sequence using the input read so far,
or can take additional input to complete a longer key sequence).

If Reline doesn’t receive further input within the timeout,
it uses the shorter but complete key sequence.

If this variable is set to a value less than or equal to zero, or to a non-numeric value,
Reline waits until another key is pressed to decide which key sequence to complete.

The default `'500'`.

### `show-all-if-ambiguous`

If set to `'on'`, input that has more than one possible completion
cause the completions to be listed immediately (instead of ringing the bell).

The default is `'off'`.

### `show-mode-in-prompt`

If set to `'on'`, prefixed the mode string to the displayed prompt;
see [Mode Strings](rdoc-ref:for_users.md@Mode+Strings).

The default is `'off'`.

### `vi-cmd-mode-string`

Specifies the mode string for Vi command mode;
see [Mode Strings](rdoc-ref:for_users.md@Mode+Strings).

The default is ‘(cmd)’.

### `vi-ins-mode-string`

Specifies the mode string for Vi insertion mode;
see [Mode Strings](rdoc-ref:for_users.md@Mode+Strings).

The default is ‘(ins)’.

### Mode Strings

A _mode string_ is a string that is to be displayed immediately before the prompt string
when variable [show-mode-in-prompt](rdoc-ref:for_users.md@show-mode-in-prompt) is set to `'on'`.

There are three mode strings:

- Emacs mode string:
  the value of variable [emacs-mode-string](rdoc-ref:for_users.md@emacs-mode-string);
  effective when variable [editing-mode](rdoc-ref:for_users.md@editing-mode) is `'emacs'`.
  Default value is `'@'`.
- Vi command mode string:
  the value of variable [vi-cmd-mode-string](rdoc-ref:for_users.md@vi-cmd-mode-string);
  effective when variable [editing-mode](rdoc-ref:for_users.md@editing-mode) is `'vi'`
  and the editing is in command mode.
  Default value is `'(cmd)'`.
- Vi insertion mode string:
  the value of variable [vi-ins-mode-string](rdoc-ref:for_users.md@vi-ins-mode-string);
  effective when variable [editing-mode](rdoc-ref:for_users.md@editing-mode) is `'vi'`
  and the editing is in insertion mode.
  Default value is `'(ins)'`.

The mode string may include [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code),
which can affect the color (foreground and background) and font (bold, italic, etc.) of the display.
The ANSI escape codes must be preceded by escape `\1` and followed by escape `\2`.

Example (turns the mode string green):

```
"\1\e[32mabcd \e[0m\2"
```

