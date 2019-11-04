class Raft::Peer
  alis SKT = TCPSocket|OpenSSL::SSL::Socket::Client

  # The address of the peer
  getter address : String

  # SSL Context for the peer
  property ssl : OpenSSL::SSL::Context?

  # The hostname of the peer
  getter host : String

  # The port of the peer
  getter port : Int32 = 4290

  # :nodoc:
  @socket : SKT?

  getter next_index : UInt64
  getter match_index : UInt64

  def self.new(address : String, ssl : OpenSSL::SSL::Context? = nil)
    host, port = address.split(':')
    new host, port.to_i, ssl
  end

  def initialize(@host, @port, @ssl = nil)
    @socket = nil
    socket
  end

  def send(request : Raft::RPC::Packet)
    request.to_io(socket, FM)
  end

  def read
    packet = Raft::RPC::Packet.new(socket, FM)
  end

  private def socket : SKT
    return @socket if @socket && !@socket.closed?
    skt = TCPSocket.new(@host, @port)
    ssl = @ssl
    if ssl
      @socket = OpenSSL::SSL::Socket::Client.new(skt, context: ssl, sync_close: true, hostname: @host)
    else
      @socket = skt
    end
    @socket
  end
end
