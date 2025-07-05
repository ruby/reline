# For Users

This page is for the user of a console application
that uses module Reline.

For other usages, see [Your Reline](rdoc-ref:README.md@Your+Reline).

Note that the usages described here are the _default_ usages for Reline.
A console application that uses module Reline may have implemented different usages.

## The Basics

Reline lets you edit typed command-line text.

These are the basic editing commands:

- Left-Arrow or Ctrl-b: move the cursor one character backward.
- Right-Arrow or Ctrl-f: move the cursor one character forward.
- Home or Ctrl-a: move the cursor to the beginning of the line.
- End or Ctrl-e: move the cursor to the end of the line.
- Alt-b: move the cursor backward to the beginning of a word.
- Alt-f: move the cursor forward to the end of a word.

- Delete or Ctrl-d: remove the character at the cursor.
- Backspace: remove the character before the cursor.

- Printing characters: insert text at the cursor;
  existing characters to the right of the cursor are move rightward.

- Ctrl-_: undo the last editing command.
- Ctrl-l: clear the screen and reprint the current line at the top.

left- and right-arrows: navigation
end and home: navigation
delete and backspace: removal
typing: insertion
Ctrl-_: undo
tab: completion

up- and down-arrows: history

### Command Line

### History

## Command Line Details

### Auto-Completion

### Moving the Cursor

### Deleting Text

### Inserting Text

### Killing and Yanking

## Command History Details

### Scrolling

### Searching


