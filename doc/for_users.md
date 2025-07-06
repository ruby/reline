# For Users

This page is for the user of a console application
that uses module Reline.

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
