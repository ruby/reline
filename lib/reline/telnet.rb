# A telnet connection as the input of Reline::ANSI: a line editor on the
# terminal of a telnet client.
#
#   telnet = Reline::Telnet.new(socket)
#   Reline.io_gate = telnet.gate
#   line = Reline.readmultiline("> ") { true }
#
# A telnet client mixes control sequences (IAC, 0xFF) into the keys: the
# option negotiation at the start, and the report of the window size
# (NAWS). Reline::Telnet negotiates (echo by the server, one key at a time,
# the window size, 8-bit data) and takes the sequences out of the keys.
# The window size reaches Reline.screen_size= and Ctrl-C (the byte 3, or
# IAC IP) reaches Reline.line_editor.interrupt; on_resize and on_interrupt
# change that. A host that reads the socket itself (to see Ctrl-C while
# it evaluates) calls feed with each chunk and gives Reline the keys.
class Reline::Telnet
  IAC = 255
  DONT = 254
  DO = 253
  WONT = 252
  WILL = 251
  SB = 250
  IP = 244
  SE = 240
  OPT_BINARY = 0
  OPT_ECHO = 1
  OPT_SGA = 3
  OPT_NAWS = 31

  # the options the server offers (WILL) and asks of the client (DO)
  OFFERS = [OPT_ECHO, OPT_SGA, OPT_BINARY].freeze
  ASKS = [OPT_NAWS, OPT_BINARY].freeze

  attr_reader :rows, :columns
  attr_accessor :on_resize, :on_interrupt

  # io: the connection (a socket, or any IO with readpartial, wait_readable
  # and write). negotiate: false skips the negotiation at the start.
  def initialize(io, negotiate: true)
    @io = io
    @carry = String.new(encoding: Encoding::ASCII_8BIT)
    @buf = []
    @eof = false
    @rows = @columns = nil
    @on_resize = ->(rows, columns) { Reline.screen_size = [rows, columns] }
    @on_interrupt = -> { Reline.line_editor.interrupt }
    self.negotiate if negotiate
  end

  # Sends the offers and the requests of the server.
  def negotiate
    seq = OFFERS.flat_map { |o| [IAC, WILL, o] } + ASKS.flat_map { |o| [IAC, DO, o] }
    @io.write seq.pack("C*")
  end

  # The ANSI gate on the connection, for Reline.io_gate=.
  def gate
    Reline::ANSI.new(input: self, output: @io, terminal: true)
  end

  # The keys of chunk, as an Array of bytes: the control sequences are
  # taken out, the negotiation is answered, NAWS calls on_resize and Ctrl-C
  # calls on_interrupt. A sequence that ends past the chunk waits for the
  # next one.
  def feed(chunk)
    buf = @carry + chunk.b
    @carry = String.new(encoding: Encoding::ASCII_8BIT)
    keys = []
    i = 0
    while i < buf.bytesize
      b = buf.getbyte(i)
      if b == 3
        @on_interrupt&.call
        i += 1
        next
      end
      if b != IAC
        keys << b
        i += 1
        next
      end
      cmd = buf.getbyte(i + 1)
      if cmd.nil?
        @carry = buf.byteslice(i..-1)
        break
      end
      case cmd
      when IAC
        keys << IAC
        i += 2
      when IP
        @on_interrupt&.call
        i += 2
      when DONT, DO, WONT, WILL
        opt = buf.getbyte(i + 2)
        if opt.nil?
          @carry = buf.byteslice(i..-1)
          break
        end
        answer(cmd, opt)
        i += 3
      when SB
        e = buf.index([IAC, SE].pack("C*"), i)
        if e.nil?
          @carry = buf.byteslice(i..-1)
          break
        end
        subnegotiation(buf.byteslice(i + 2, e - i - 2))
        i = e + 2
      else
        i += 2
      end
    end
    keys
  end

  # The input of the gate: the keys of the connection.

  def tty?
    false
  end

  def external_encoding
    Encoding.default_external
  end

  def wait_readable(timeout = nil)
    return self unless @buf.empty?
    return self if @eof
    @io.wait_readable(timeout)
  end

  def getbyte
    fill while @buf.empty? && !@eof
    @buf.shift
  end

  def getc
    b = getbyte
    b && b.chr
  end

  def readpartial(n)
    fill if @buf.empty? && !@eof
    @buf.shift(n).pack("C*")
  end

  private

  # Reads one chunk of the connection into the keys.
  def fill
    @buf.concat feed(@io.readpartial(1024))
  rescue EOFError, IOError, SystemCallError
    @eof = true
  end

  # An option the server did not offer or ask is refused.
  def answer(cmd, opt)
    case cmd
    when WILL
      @io.write [IAC, DONT, opt].pack("C*") unless ASKS.include?(opt)
    when DO
      @io.write [IAC, WONT, opt].pack("C*") unless OFFERS.include?(opt)
    end
  end

  def subnegotiation(body)
    return unless body.getbyte(0) == OPT_NAWS && body.bytesize >= 5
    @columns = (body.getbyte(1) << 8) | body.getbyte(2)
    @rows = (body.getbyte(3) << 8) | body.getbyte(4)
    @on_resize&.call(@rows, @columns)
  end
end
