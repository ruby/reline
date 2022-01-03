source 'https://rubygems.org'

gemspec

group :development do
  gem 'bundler'
  gem 'rake'
  gem 'test-unit'
  is_unix = RUBY_PLATFORM =~ /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
  gem 'vterm', '>= 0.0.5' if is_unix && ENV['WITH_VTERM']
  gem 'yamatanooroti', '>= 0.0.9'
  gem 'irb', '>= 1.3.6'
end
