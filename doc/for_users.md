# For Users

This page is for the user of a console application that uses module Reline,
such as Ruby's own:

- [irb](https://ruby.github.io/irb/index.html): Interactive Ruby.
- [debug](https://github.com/ruby/debug): Ruby debugger.
- [ri](https://ruby.github.io/rdoc/RI_md.html) Ruby information.

For other usages, see [Your Reline](rdoc-ref:README.md@Your+Reline).

Note that the usages described here are the _default_ usages for Reline.
A console application that uses module Reline may have implemented different usages.

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
- `Esc` denotes the [Escape key](https://en.wikipedia.org/wiki/Esc_key).
- `Home` denotes the [Home key](https://en.wikipedia.org/wiki/Home_key).
- `Ret` denotes the [Enter key](https://en.wikipedia.org/wiki/Enter_key).
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

Cursor-movement commands:

- Character-by-character:

    - `←` or `C-b`: backward one character.
    - `→` or `C-f`: forward one character.
Word-by-word:

    - `M-b`: backward to the beginning of a word.
    - `M-f`: forward to the end of a word.

Whole line:

    - `Home` or `C-a`: backward to the beginning of the line.
    - `End` or `C-e`: forward to the end of the line.

Text-deletion commands:

- `Del` or `C-d`: remove the character to the right the cursor
- `Bsp`: remove the character to the left the cursor.

In either case, existing characters to the right of the cursor are move leftward
to "close the gap."

Text-insertion commands:

- Any printable character: insert the character at the cursor;
  existing characters to the right of the cursor are move rightward to "make room."

Other commands:

- `C-_`: undo the last editing command;
  may be repeated until the original (unedited) line is restored.
- `C-l`: clear the screen and reprint the current line at the top.

## Killing and Yanking

The _kill ring_ is a stack containing zero or more strings
that have been killed by kill commands.

Kill commands; each kills text beginning at the cursor
and pushes that text onto the kill ring.

- `C-k`: kill to the end of the line.
- `M-d`: kill to the end of the current word,
  or, if between words, to the end of the next word.
- `M-Del`: kill to the start of the current word,
  or, if between words, to the start of the previous word.
- `C-w`: kill to the previous whitespace.

Yank commands; pops text from the kill ring
amd inserts the that text at the cursor.

- `C-y`: yank the most recently killed text.
- `M-y`: rotate the kill ring, and yank the new top.
  Available only if the immediately preceding command was `C-y` or another `M-y`;
  otherwise, does nothing.

## Arguments

[TODO]

## History

- `↑`: scroll upward in history (if not already at the earliest history).
- `↓`: scroll downward in history (if not already at the current line).
- `C-r`: search backward.
- `C-g`: abort search.
- `C-j`: abort search.

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

