@echo off
echo "-- Download test/readline --"
mkdir test\ext\readline
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/helper.rb %CD%\test\ext\readline\helper.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline.rb %CD%\test\ext\readline\test_readline.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/test/readline/test_readline_history.rb %CD%\test\ext\readline\test_readline_history.rb

mkdir tool
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/colorize.rb tool

mkdir tool\lib
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/leakchecker.rb %CD%\tool\lib\leakchecker.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/envutil.rb %CD%\tool\lib\envutil.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/colorize.rb %CD%\tool\lib\colorize.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/find_executable.rb %CD%\tool\lib\find_executable.rb

mkdir tool\lib\unit\minitest
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/minitest/unit.rb %CD%\tool\lib\minitest\unit.rb

mkdir tool\lib\unit\test
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit.rb %CD%\tool\lib\test\unit.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/assertions.rb %CD%\tool\lib\test\unit\assertions.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/core_assertions.rb %CD%\tool\lib\test\unit\core_assertions.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/parallel.rb %CD%\tool\lib\test\unit\parallel.rb
bitsadmin.exe /TRANSFER get_readline_test_file https://raw.githubusercontent.com/ruby/ruby/trunk/tool/lib/test/unit/testcase.rb %CD%\tool\lib\test\unit\testcase.rb

echo "-- Finish download test/readline --"

tree /f

exit /b 0
