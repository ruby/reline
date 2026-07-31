
module Reline
  class IO
    RESET_COLOR = "\e[0m"

    def self.decide_io_gate
      if ENV['TERM'] == 'dumb'
        Reline::Dumb.new
      else
        require 'reline/io/ansi'

        case RbConfig::CONFIG['host_os']
        when /mswin|mingw|bccwin|wince|emc/
          require 'reline/io/windows'
          io = Reline::Windows.new
          if io.msys_tty? || !STDIN.tty?
            # In either case stdin is not a console (a Cygwin/MSYS pty pipe such
            # as mintty, or a redirect), so the Win32 console input API cannot
            # read it.
            Reline::ANSI.new
          else
            io
          end
        else
          # Ruby built with the msys/cygwin runtime also reaches here. Its tty layer
          # speaks ANSI in any terminal (mintty pty or Windows console), so the
          # Win32 console API must not be used. https://github.com/ruby/reline/issues/903
          Reline::ANSI.new
        end
      end
    end

    def dumb?
      false
    end

    def win?
      false
    end

    def reset_color_sequence
      self.class::RESET_COLOR
    end

    # Read a single encoding valid character from the input.
    def read_single_char(timeout_second)
      buffer = String.new(encoding: Encoding::ASCII_8BIT)
      loop do
        timeout = buffer.empty? ? Float::INFINITY : timeout_second
        c = getc(timeout)
        return unless c

        buffer << c
        encoded = buffer.dup.force_encoding(encoding)
        return encoded if encoded.valid_encoding?
      end
    end
  end
end

require 'reline/io/dumb'
