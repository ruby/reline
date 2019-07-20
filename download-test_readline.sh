#!/bin/sh
echo "-- Download test/readline --"
mkdir -p ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/helper.rb -P ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline.rb -P ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline_history.rb -P ./test/ext/readline

mkdir -p ./tool/
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/colorize.rb -P ./tool

mkdir -p ./tool/lib/
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/leakchecker.rb -P ./tool/lib
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/envutil.rb -P ./tool/lib
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/colorize.rb -P ./tool/lib
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/find_executable.rb -P ./tool/lib

mkdir -p ./tool/lib/unit/minitest
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/minitest/unit.rb -P ./tool/lib/minitest

mkdir -p ./tool/lib/unit/test
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit.rb -P ./tool/lib/test
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/assertions.rb -P ./tool/lib/test/unit
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/core_assertions.rb -P ./tool/lib/test/unit
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/parallel.rb -P ./tool/lib/test/unit
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/testcase.rb -P ./tool/lib/test/unit

echo "-- Finish download test/readline --"
