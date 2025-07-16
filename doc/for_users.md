# For Users

This page is for the user of a console application that uses module Reline,
such as Ruby's own:

- [irb](https://ruby.github.io/irb/index.html): Interactive Ruby.
- [debug](https://github.com/ruby/debug): Ruby debugger.
- [ri](https://ruby.github.io/rdoc/RI_md.html) Ruby information.

For other usages, see [Your Reline](rdoc-ref:README.md@Your+Reline).

Note that the usages described here are the _default_ usages for Reline.
A console application that uses module Reline may have implemented different usages.

## The Basics

Reline lets you edit typed command-line text.

Cursor-movement commands:

- `Left-Arrow` or `Ctrl-b`: backward one character.
- `Right-Arrow` or `Ctrl-f`: forward one character.
- `Alt-b`: backward to the beginning of a word.
- `Alt-f`: forward to the end of a word.
- `Home` or `Ctrl-a`: backward to the beginning of the line.
- `End` or `Ctrl-e`: forward to the end of the line.

Text-deletion commands:

- `Delete` or `Ctrl-d`: remove the character to the right the cursor.
- `Backspace`: remove the character to the left the cursor.

Text-insertion commands:

- Printable characters: insert text at the cursor;
  existing characters to the right of the cursor are move rightward.

Other commands:

- `Ctrl-_`: undo the last editing command.
- `Ctrl-l`: clear the screen and reprint the current line at the top.

## Killing and Yanking

Kill commands; each kills text beginning at the cursor:

- `Ctrl-k`: kill to the end of the line.
- `Alt-d`: kill to the end of the current word,
  or, if between words, to the end of the next word.
- `Alt-Delete`: kill to the start of the current word,
  or, if between words, to the start of the previous word.
- `Ctrl-w`: kill to the previous whitespace.`

Yank commands; each inserts killed text at the cursor:

- `Ctrl-y`: yank the most recently killed text.
- `Alt-y`: rotate the kill-ring, and yank the new top.
  Available only if the immediately preceding command was `Ctrl-y` or another `Alt-y`;
  otherwise, does nothing.

## Arguments

[TODO]

## History

- `Ctrl-r`: search backward.
- `Ctrl-g`: abort search.
- `Ctrl-j`: abort search.
- `Up-Arrow`: scroll upward.
- `Down-Arrow`: scroll downward.

## Init File

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
  the if-block consists of the lines between `$if` and `$endif`:

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
the expressions in the `$if` block are evaluated;
if it evaluates to `false`,
the expressions in the `$else` block (if any) are evaluated.

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

[TODO] 

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
and prefixing an `Escape` character.

The default value is `'on'`, but Reline sets it to `'off'`
if the locale contains characters whose encodings may include bytes with the eighth bit set.

### `disable-completion`

If set to `'on'`, Reline inhibits word completion.
Completion characters (`Tab`, `Alt-?`, and `Alt-*`) lose their usual meanings,
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

Default: `Escape` and `Ctrl-j`.

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

