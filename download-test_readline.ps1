<# Copies files from ruby/ruby/test/readline, renames
   readline.so to readline.no so tests won't run on it

   Note: the file name is not reset using rake or Actions scripts
#>

$__dir__ = $PSScriptRoot

$wc = $(New-Object System.Net.WebClient)

$ruby_uri = "https://raw.githubusercontent.com/ruby/ruby/master"

function download_files($uri2, $dir, $files) {
  if ( !(Test-Path -Path "$__dir__/$dir" -PathType Container)) {
    New-Item -Path "$__dir__/$dir" -ItemType Directory 1> $null
  }
  foreach ($file in $files) {
    try {
      $wc.DownloadFile("$ruby_uri/$uri2/$file", "$__dir__/$dir/$file")
    } catch {
      Write-Host "Can't download $ruby_uri/$uri2/$file"
      exit 1
    }
  }
}

$files = "helper.rb", "test_readline.rb", "test_readline_history.rb"
download_files "test/readline" "test/ext/readline" $files

$files = "leakchecker.rb", "envutil.rb", "colorize.rb", "find_executable.rb"
download_files "tool/lib" "tool/lib" $files

download_files "tool/lib/minitest" "tool/lib/minitest" @("unit.rb")
download_files "tool/lib/test"     "tool/lib/test"     @("unit.rb")

$files = "assertions.rb", "core_assertions.rb", "parallel.rb", "testcase.rb"
download_files "tool/lib/test/unit" "tool/lib/test/unit" $files

# below renames readline.so to readline.no
$archdir = ruby.exe -e "print RbConfig::CONFIG['archdir']"
$readline_so = "$archdir/readline"

if (Test-Path -Path "$readline_so.so" -PathType leaf) {
  Rename-Item -Path "$readline_so.so" -NewName "$readline_so.no"
}
