require_relative 'helper'

class Reline::TelnetTest < Reline::TestCase
  # Both directions of a connection over two pipes: the test is the client.
  class Duplex
    def initialize(reader, writer)
      @reader = reader
      @writer = writer
    end

    def readpartial(n)
      @reader.readpartial(n)
    end

    def wait_readable(timeout = nil)
      @reader.wait_readable(timeout)
    end

    def write(s)
      @writer.write(s)
    end

    def flush
      @writer.flush
    end

    def <<(s)
      @writer << s
      self
    end
  end

  IAC = Reline::Telnet::IAC
  WILL = Reline::Telnet::WILL
  WONT = Reline::Telnet::WONT
  DO = Reline::Telnet::DO
  DONT = Reline::Telnet::DONT
  SB = Reline::Telnet::SB
  SE = Reline::Telnet::SE
  IP = Reline::Telnet::IP

  def setup
    Reline.send(:test_mode)
    @to_server_r, @to_server_w = IO.pipe
    @to_client_r, @to_client_w = IO.pipe
    @conn = Duplex.new(@to_server_r, @to_client_w)
  end

  def teardown
    [@to_server_r, @to_server_w, @to_client_r, @to_client_w].each { |io| io.close unless io.closed? }
    Reline.test_reset
  end

  def bytes(*a)
    a.flatten.pack("C*")
  end

  # what the client has received so far
  def from_server
    @to_client_r.read_nonblock(4096)
  rescue IO::WaitReadable
    ""
  end

  def test_negotiation_at_the_start
    Reline::Telnet.new(@conn)
    offers = bytes(IAC, WILL, 1, IAC, WILL, 3, IAC, WILL, 0)
    asks = bytes(IAC, DO, 31, IAC, DO, 0)
    assert_equal offers + asks, from_server
  end

  def test_keys_without_the_sequences
    telnet = Reline::Telnet.new(@conn, negotiate: false)
    resized = []
    interrupts = 0
    telnet.on_resize = ->(rows, columns) { resized << [rows, columns] }
    telnet.on_interrupt = -> { interrupts += 1 }
    @to_server_w.write bytes(IAC, DO, 1) + "ab" + bytes(IAC, WILL, 31) +
      bytes(IAC, SB, 31, 0, 100, 0, 30, IAC, SE) + bytes(IAC, WILL, 24) +
      bytes(IAC, IP) + "c" + bytes(IAC, IAC) + "\x03d"
    assert_equal ["a", "b", "c", 255.chr, "d"], 5.times.map { telnet.getc }
    assert_equal [30, 100], [telnet.rows, telnet.columns]
    assert_equal [[30, 100]], resized
    assert_equal 2, interrupts
    # the client's acceptance of an offer and its offer of NAWS need no
    # answer; an option the server does not want is refused
    assert_equal bytes(IAC, DONT, 24), from_server
  end

  def test_sequence_split_across_chunks
    telnet = Reline::Telnet.new(@conn, negotiate: false)
    assert_equal [], telnet.feed(bytes(IAC))
    assert_equal ["a".ord], telnet.feed(bytes(DO, 1) + "a")
    assert_equal [], telnet.feed(bytes(IAC, SB, 31, 0, 80))
    assert_equal ["b".ord], telnet.feed(bytes(0, 24, IAC, SE) + "b")
    assert_equal [24, 80], [telnet.rows, telnet.columns]
  end

  def test_end_of_the_connection
    telnet = Reline::Telnet.new(@conn, negotiate: false)
    @to_server_w.write "a"
    @to_server_w.close
    assert_equal "a".ord, telnet.getbyte
    assert_nil telnet.getbyte
    assert_equal "", telnet.readpartial(10)
  end

  def test_readmultiline_through_the_gate
    telnet = Reline::Telnet.new(@conn)
    Reline.io_gate = telnet.gate
    assert_true Reline.io_gate.terminal?
    # the client accepts echo, reports its size, answers the cursor
    # position query and types a line
    @to_server_w.write bytes(IAC, DO, 1, IAC, SB, 31, 0, 100, 0, 30, IAC, SE) + "\e[1;1Rhi\r"
    assert_equal "hi", Reline.readmultiline(&proc{ true })
    assert_equal [30, 100], Reline.get_screen_size
  ensure
    Reline.io_gate = nil
  end
end
