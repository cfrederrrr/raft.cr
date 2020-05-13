class Raft::Peer
  getter id : Int64

  # :nodoc:
  @socket : TCPSocket|OpenSSL::SSL::Socket::Client

  # property timeout : Float32 = Time::Span.new(nanoseconds: 300_000_000)

  getter next_index : UInt64 = 0_u64
  getter match_index : UInt64 = 0_u64

  def self.handshake(
      packet : RPC::Hello,
      socket : TCPSocket|OpenSSL::SSL::Socket::Client
    )
    spawn do
      packet.to_io(socket, IO::ByteFormat::NetworkEndian)
      socket.flush
    end

    spawn do
      result = RPC::Packet.new(socket, IO::ByteFormat::NetworkEndian)
      if result.is_a?(RPC::Hello)
      end
    end
  end

  # TODO: initialze peer with a socket created outside
  #   i.e. if the socket connects, and a handshake is
  #        negotiated, pass the socket as an argument
  #        to the initializer along with the id parsed
  #        from the packet
  #        if the socket does not connect, then no peer
  #        can be initialized, and then can't be added
  #        to the server's peer list
  def initialize(@id, @socket, @next_index, @match_index)
    @socket = nil
  end

  def send(packet : RPC::Packet)
    packet.to_io(socket, IO::ByteFormat::NetworkEndian)
    socket.flush
  end

  def read(timeout : Float32?)
    RPC::Packet.new(socket, IO::ByteFormat::NetworkEndian)
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
