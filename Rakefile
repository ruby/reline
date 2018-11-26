require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test_shift_jis) do |t|
  t.ruby_opts << %q{-I. -e "RELINE_TEST_ENCODING=Encoding::UTF_8"}
  t.libs << 'test'
  t.libs << 'lib'
  t.loader = :direct
  t.pattern = 'test/**/*_test.rb'
end

Rake::TestTask.new(:test_utf_8) do |t|
  t.ruby_opts << %q{-I. -e "RELINE_TEST_ENCODING=Encoding::Shift_JIS"}
  t.libs << 'test'
  t.libs << 'lib'
  t.loader = :direct
  t.pattern = 'test/**/*_test.rb'
end

task test: [:test_shift_jis, :test_utf_8]

task default: :test
