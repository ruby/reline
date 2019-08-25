@echo off
echo "-- Download test/readline --"
mkdir test\ext\readline
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/helper.rb test\ext\readline
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline.rb test\ext\readline
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline_history.rb test\ext\readline

mkdir tool
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/colorize.rb tool

mkdir tool\lib
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/leakchecker.rb tool\lib
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/envutil.rb tool\lib
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/colorize.rb tool\lib
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/find_executable.rb tool\lib

mkdir tool\lib\unit\minitest
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/minitest/unit.rb tool\lib\minitest

mkdir tool\lib\unit\test
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit.rb tool\lib\test
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/assertions.rb tool\lib\test\unit
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/core_assertions.rb tool\lib\test\unit
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/parallel.rb tool\lib\test\unit
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/testcase.rb tool\lib\test\unit

echo "-- Finish download test/readline --"

exit /b 0
