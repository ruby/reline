# For Developers

This page is for the developer who wants to use `reline`
in a console application.

Other pages:

- Page [README](README.md) gives a general description
  of `reline` and what it does.
- Page [For Users](for_users.md)
  is for the user of a console application
  that uses module `reline`.


The first thing to know about `reline` is that you make it available in your program with:

```
require 'reline'
```

## Usage

### Single line editing mode

It's compatible with the readline standard library.

See [the document of readline stdlib](https://ruby-doc.org/stdlib/exts/readline/Readline.html) or [bin/example](https://github.com/ruby/reline/blob/master/bin/example).

### Multi-line editing mode

```ruby
require "reline"

prompt = 'prompt> '
use_history = true

begin
  while true
    text = Reline.readmultiline(prompt, use_history) do |multiline_input|
      # Accept the input until `end` is entered
      multiline_input.split.last == "end"
    end

    puts 'You entered:'
    puts text
  end
# If you want to exit, type Ctrl-C
rescue Interrupt
  puts '^C'
  exit 0
end
```

```bash
$ ruby example.rb
prompt> aaa
prompt> bbb
prompt> end
You entered:
aaa
bbb
end
```

See also: [test/reline/yamatanooroti/multiline_repl](https://github.com/ruby/reline/blob/master/test/reline/yamatanooroti/multiline_repl)

## Documentation

### Reline::Face

You can modify the text color and text decorations in your terminal emulator.
See [doc/reline/face.md](./doc/reline/face.md)

### Run tests

> **Note**
> Please make sure you have `libvterm` installed for `yamatanooroti` tests (integration tests).

If you use Homebrew, you can install it by running `brew install libvterm`.

```bash
WITH_VTERM=1 bundle install
WITH_VTERM=1 bundle exec rake test test_yamatanooroti
```

## Releasing

```bash
rake release
gh release create vX.Y.Z --generate-notes
```

