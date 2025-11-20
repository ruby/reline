## Initialization File

A Reline application has default key bindings and variable definitions,
as determined by the application itself.

You can customize the application's behavior by specifying key bindings and variable definitions
in an _initialization file_.
The initialization file may define:

- [Key Bindings][key bindings]: Definitions relating keys to variables.
- [Variables][variables]: Definitions for certain variables.
- [Directives][directives]: Conditional initialization and file inclusion.

When a Reline application starts, it reads a user-provided initialization file,
whose path is determined thus:

- The path specified by `ENV['INPUTRC']` if defined.
- Otherwise, `~/.inputrc`, if that file exists.
- Otherwise, if `ENV['XDG_CONFIG_HOME']` is defined (call its value `path`),
  `File.join(path, 'readline/inputrc')`.
- Otherwise, `'~/.config/readline/inputrc'`, if that file exists.
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
"\1\e[32m\2abcd \1\e[0m\2"
```

### Key Bindings

In brief:

```
"\C-x\M-r":  "Ruby!"          # Key sequence bound to text.
"\C-x\M-c":  ed-clear-screen  # Key sequence bound to function.
Meta-l:      " | less"        # Key name bound to text.
Control-b:   ed-clear-screen  # Key name bound to function.
```

A key or key sequence may be bound to:

- Text to be inserted when the key or key sequence is typed in:
  in effect a [macro][macro].
- A Reline function that is to be called when the key or key sequence is typed in:
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

You can bind a key sequence to a Reline function,
so that the function is called when the key sequence is typed as input.
See [Functions][functions].

This example binds a key sequence to the function `ed-clear-screen`,
which means that in the application pressing `Alt-x` clears the screen
and reprints the prompt at the top:

```
"\M-x": ed-clear-screen
```

This binding is the same as the default binding for `C-l`.
Note that this new binding would override the old one, if any, for that key,
but does not disturb other bindings (`C-l` is still bound to `ed-clear-screen`).

#### Key Names

You can bind a single key to text or a function using its _key name_
(instead of the key sequence notation):

```
Control-b: ed-clear-screen
Meta-L: " | less"
```

#### Functions

These are the functions available for binding by a key or key sequence:

- `ed-argument-digit`
- `ed-beginning-of-history`
- `ed-clear-screen`
- `ed-delete-next-char`
- `ed-delete-prev-char`
- `ed-delete-prev-word`
- `ed-digit`
- `ed-end-of-history`
- `ed-kill-line`
- `ed-move-to-beg`
- `ed-move-to-end`
- `ed-newline`
- `ed-next-char`
- `ed-next-history`
- `ed-prev-char`
- `ed-prev-history`
- `ed-prev-word`
- `ed-search-next-history`
- `ed-search-prev-history`
- `ed-transpose-chars`
- `ed-transpose-words`
- `ed-unassigned end # do nothing`
- `em-capitol-case`
- `em-delete`
- `em-delete-next-word`
- `em-delete-or-list`
- `em-delete-prev-char`
- `em-exchange-mark`
- `em-kill-line`
- `em-kill-region`
- `em-lower-case`
- `em-next-word`
- `em-set-mark`
- `em-upper-case`
- `em-yank`
- `em-yank-pop`
- `emacs-editing-mode`
- `incremental-search-history`
- `key-delete`
- `key-newline`
- `process-key`
- `run-for-operators`
- `search-next-char`
- `search-prev-char`
- `vi-add`
- `vi-add-at-eol`
- `vi-change-meta`
- `vi-change-to-eol`
- `vi-command-mode`
- `vi-delete-meta`
- `vi-delete-prev-char`
- `vi-editing-mode`
- `vi-end-big-word`
- `vi-end-word`
- `vi-first-print`
- `vi-histedit`
- `vi-insert`
- `vi-insert-at-bol`
- `vi-join-lines`
- `vi-kill-line-prev`
- `vi-list-or-eof`
- `vi-next-big-word`
- `vi-next-char`
- `vi-next-word`
- `vi-paste-next`
- `vi-paste-prev`
- `vi-prev-big-word`
- `vi-prev-char`
- `vi-prev-word`
- `vi-replace-char`
- `vi-search-next`
- `vi-search-prev`
- `vi-to-column`
- `vi-to-history-line`
- `vi-to-next-char`
- `vi-to-prev-char`
- `vi-yank`
- `vi-zero`

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

#### `$include`

The `$include` directive takes a single argument,
which is the path to a file that is to be read and evaluated
as if it were part of the initialization file.

Pro tip: You can use the `$include` directive to override (in full or in part)
another initialization file:

    ```
    $include <filepath>
    # Assignments and directives that will override.
    # ...

[directives]:   rdoc-ref:initialization_file.md@Directives
[key bindings]: rdoc-ref:initialization_file.md@Key+Bindings
[functions]:    rdoc-ref:initialization_file.md@Functions
[variables]:    rdoc-ref:initialization_file.md@Variables
