class Raft::Peer
  # The address of the peer
  getter address : String

  # SSL Context for the peer
  property tls : OpenSSL::SSL::Context::Client?

  # The port of the peer
  getter port : Int32 = 4290

  getter id : Int64
  property timeout : Float32 = Time::Span.new(nanoseconds: 300_000_000)

  # :nodoc:
  @socket : TCPSocket|OpenSSL::SSL::Socket::Client?

  getter next_index : UInt64 = 0_u64
  getter match_index : UInt64 = 0_u64

  def self.new(
      id : Int64,
      address : String,
      tls : OpenSSL::SSL::Context::Client? = nil
    )

    host, port = address.split(':')
    new host, port, port.to_i, tls
  end

  def initialize(@id, @address, @port, @tls = nil)
    @socket = nil
  end

  def send(request : Raft::RPC::Packet)
    request.to_io(socket, FM)
    socket.flush
  end

  def read(timeout : Float32?)
    RPC::Packet.new(socket, NetworkFormat)
  end

  def read
    packet = RPC::Packet.new(socket, NetworkFormat)
    callback = yield(packet)
    send(callback)
  end

  private def socket : TCPSocket|OpenSSL::SSL::Socket::Client
    return @socket if @socket && !@socket.closed?
    skt = TCPSocket.new(@host, @port)
    if tls = @tls
      @socket = OpenSSL::SSL::Socket::Client.new(skt, context: tls, sync_close: true, hostname: @host)
    else
      @socket = skt
    end

    @socket.read_timeout = @timeout
    return @socket
  end
end
