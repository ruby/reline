require 'bundler/gem_tasks'
require 'rake/testtask'

ENCODING_LIST = {
  test_shift_jis: Encoding::Shift_JIS,
  test_euc_jp: Encoding::EUC_JP,
  test_utf_8: Encoding::UTF_8,
  test_cp932: Encoding::Windows_31J,
  #test_ibm437: Encoding::IBM437
}

ENCODING_LIST.each_pair do |task_name, encoding|
  Rake::TestTask.new(task_name) do |t|
    t.ruby_opts << %Q{-I. -e "RELINE_TEST_ENCODING=Encoding.find('#{encoding.name}') ; puts %Q{\nTest Encoding: #{encoding.name}}"}
    t.libs << 'test'
    t.libs << 'lib'
    t.loader = :direct
    t.pattern = 'test/reline/test_*.rb'
  end
end

task test: ENCODING_LIST.keys


Rake::TestTask.new(:test_yamatanooroti) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  #t.loader = :direct
  t.pattern = 'test/reline/yamatanooroti/test_*.rb'
end


task default: :test
