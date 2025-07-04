[![Gem Version](https://badge.fury.io/rb/reline.svg)](https://badge.fury.io/rb/reline)
[![CI](https://github.com/ruby/reline/actions/workflows/reline.yml/badge.svg)](https://github.com/ruby/reline/actions/workflows/reline.yml)

# Reline

Module Reline is the Ruby library that supports:

- Editing text on the command line:

    - Use Left-Arrow and Right-Arrow keys (`←` and `→`) to move the cursor within the text you've typed.
    - Use Delete and Backspace keys to remove characters from the typed text.
    - Type to insert text at the cursor.
    - Use Tab key to invoke auto-completion.

- Reviewing and re-using command-line history:

    - Use Up-Arrow and Down-Arrow keys (`↑` and `↓`) to scroll among previously typed commands.
    - Use history index numbers to select and invoke commands from history.

## Your Reline

If you are the _user_ of a console application that uses Reline
(such as [IRB](https://ruby.github.io/irb/index.html)),
see [For Users](for_users.md);
see also [Reline in Action](rdoc-ref:README.md@Reline+in+Action) below.

If you are the _developer_ of a console application that uses (or will use) Reline,
see [For Developers](for_developers.md).

If you want to _contribute_ to Reline code or documentation
(enhancements or bug fixes),
see [For Contributors](for_contributors.md).

If you want to _report_ a bug in Reline code or documentation,
see [Reporting Bugs](reporting_bugs.md).

## Reline in Action

Below is a screen capture of a brief session
in [IRB](https://ruby.github.io/irb/index.html) (Interactive Ruby),
which uses Reline:

- The dark gray area of the window at the upper-right shows the keys that are being typed.
- The main part of the window shows the result of the typing.

![IRB improved by Reline](https://raw.githubusercontent.com/wiki/ruby/reline/images/irb_improved_by_reline.gif)

## License

The gem is available as open source under the terms of the [Ruby License](https://www.ruby-lang.org/en/about/license.txt).

## Acknowledgment

In developing Reline, we have used some of the implementation
of [rb-readline](https://github.com/ConnorAtherton/rb-readline),
so this library includes
[copyright notice, list of conditions and the disclaimer](../license_of_rb-readline)
under the 3-Clause BSD License.
Reline would never have been developed without rb-readline.
Thank you for the tremendous accomplishments.
