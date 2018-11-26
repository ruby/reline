require 'bundler/gem_tasks'
require 'rake/testtask'

ENCODING_LIST = {
  test_shift_jis: Encoding::UTF_8,
  test_euc_jp: Encoding::EUC_JP,
  test_utf_8: Encoding::Shift_JIS
}

ENCODING_LIST.each_pair do |task_name, encoding|
  Rake::TestTask.new(task_name) do |t|
    t.ruby_opts << %Q{-I. -e "RELINE_TEST_ENCODING=Encoding.find('#{encoding.name}')"}
    t.libs << 'test'
    t.libs << 'lib'
    t.loader = :direct
    t.pattern = 'test/**/*_test.rb'
  end
end

task test: ENCODING_LIST.keys

task default: :test
