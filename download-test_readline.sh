#!/bin/sh
echo "-- Download test/readline --"
mkdir -p ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/helper.rb -P ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline.rb -P ./test/ext/readline
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline_history.rb -P ./test/ext/readline
mkdir -p ./tool/
wget https://raw.githubusercontent.com/ruby/ruby/trunk/tool/colorize.rb -P ./tool
mkdir -p ./test/lib/
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/leakchecker.rb -P ./test/lib
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/envutil.rb -P ./test/lib
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/find_executable.rb -P ./test/lib
mkdir -p ./test/lib/unit/minitest
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/minitest/unit.rb -P ./test/lib/minitest
mkdir -p ./test/lib/unit/test
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/test/unit.rb -P ./test/lib/test
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/test/unit/assertions.rb -P ./test/lib/test/unit
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/test/unit/parallel.rb -P ./test/lib/test/unit
wget https://raw.githubusercontent.com/ruby/ruby/trunk/test/lib/test/unit/testcase.rb -P ./test/lib/test/unit
echo "-- Finish download test/readline --"
