source 'https://rubygems.org'

gemspec

is_unix = RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i

if is_unix
  # if you fail to install the vterm gem, please make sure you have `libvterm` installed.
  gem "vterm", github: "ruby/vterm-gem"
  gem "yamatanooroti", github: "ruby/yamatanooroti"
end

gem 'bundler'
gem 'rake'
gem 'test-unit'
