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
    t.ruby_opts << %Q{-I. -e "RELINE_TEST_ENCODING=Encoding.find('#{encoding.name}')"}
    t.libs << 'test'
    t.libs << 'lib'
    t.loader = :direct
    t.pattern = 'test/reline/**/test_*.rb'
  end
end

task test: ENCODING_LIST.keys


ENCODING_LIST.each_pair do |task_name, encoding|
  Rake::TestTask.new("ci-#{task_name}") do |t|
    t.ruby_opts << %Q{-I. -e "RELINE_TEST_ENCODING=Encoding.find('#{encoding.name}')"}
    t.libs << 'tool'
    t.libs << 'lib'
    t.libs << 'tool/lib'
    t.loader = :direct
    t.pattern = 'test/ext/**/test_*.rb'
  end
end

task "ci-test": ENCODING_LIST.keys.map { |task_name| "ci-#{task_name}" }

task default: :test
