source 'https://rubygems.org'

gemspec

is_unix = RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i

if is_unix && ENV['WITH_VTERM']
  gem "vterm", github: "ruby/vterm-gem"
  gem "yamatanooroti", github: "ruby/yamatanooroti"
end

gem 'bundler'
gem 'rdoc'
gem 'rake'
gem 'test-unit'
gem 'test-unit-ruby-core'
gem "power_assert", "~> 2.0" if RUBY_VERSION < '3.0' # https://github.com/ruby/power_assert/pull/61

# Only used in ci to run readline-ext test using Reline as Readline
gem 'readline'

# Only used in windows
gem 'fiddle'
