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

# Only used in ci to run readline-ext test using Reline as Readline
gem 'readline'

# Only used in windows
gem 'fiddle'
