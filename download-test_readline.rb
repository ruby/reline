# frozen_string_literal: true

# From ruby/ruby, copies readline test files & tool/lib files
# Replicates testing used in Ruby master

require 'uri'
require 'net/http'
require 'openssl'
require 'fileutils'

module HTTPS_DL

  # number of concurrent connections
  CONNECTIONS = 4

  HOST = "https://raw.githubusercontent.com"
  URI_GH = URI HOST
  BASE = "ruby/ruby/master"

  # 1st - ruby/ruby dir  , 2nd - reline dir    , 3rd - filename
  FILES = [
    ["test/readline"     , "test/ext/readline" , "helper.rb"                ],
    ["test/readline"     , "test/ext/readline" , "test_readline.rb"         ],
    ["test/readline"     , "test/ext/readline" , "test_readline_history.rb" ],
    ["tool/lib"          , "tool/lib"          , "colorize.rb"              ],
    ["tool/lib"          , "tool/lib"          , "envutil.rb"               ],
    ["tool/lib"          , "tool/lib"          , "find_executable.rb"       ],
    ["tool/lib"          , "tool/lib"          , "leakchecker.rb"           ],
    ["tool/lib/minitest" , "tool/lib/minitest" , "unit.rb"                  ],
    ["tool/lib/test"     , "tool/lib/test"     , "unit.rb"                  ],
    ["tool/lib/test/unit", "tool/lib/test/unit", "assertions.rb"            ],
    ["tool/lib/test/unit", "tool/lib/test/unit", "core_assertions.rb"       ],
    ["tool/lib/test/unit", "tool/lib/test/unit", "parallel.rb"              ],
    ["tool/lib/test/unit", "tool/lib/test/unit", "testcase.rb" ]
  ]

  class << self

    def run
      files = FILES

      dirs = FILES.map { |l| l[1] }.uniq
      dirs.each { |dir| FileUtils.mkdir_p("./#{dir}") unless Dir.exist? dir }

      connections = []

      CONNECTIONS.times do
        connections << Thread.new do
          Net::HTTP.start(URI_GH.host, URI_GH.port, :use_ssl => true,:verify_mode => OpenSSL::SSL::VERIFY_PEER) do |http|
            while (path, dir, file = files.shift)
              uri = URI("#{HOST}/#{BASE}/#{path}/#{file}")
              req = Net::HTTP::Get.new uri.request_uri
              http.request req do |res|
                unless Net::HTTPOK === res
                  STDOUT.puts "Can't download #{path}/#{file} from #{HOST}/#{BASE}/"
                  exit 1
                end
                File.binwrite "./#{dir}/#{file}", res.body
              end
            end
          end
        end
      end
      connections.each { |th| th.join }
    end
  end
end

HTTPS_DL.run
