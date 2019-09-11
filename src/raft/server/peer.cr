class Raft::Server::Peer
  getter address : String
  @ssl : OpenSSL::SSL::Context?
  @uri : URI
  @socket : IO::Buffered|OpenSSL::SSL::Socket::Client?

  getter next_index : UInt64
  getter match_index : UInt64

  def initialize(@address : String, @ssl : OpenSSL::SSL::Context? = nil)
    @uri = URI.parse(string)
    @socket = nil
  end

  def ssl=(ssl : OpenSSL::SSL::Context)
    @ssl = ssl
    socket
  end

  private def socket
    return @socket if @socket && !@socket.closed?
    skt = TCPSocket.new(@uri.host, @uri.port)
    ssl = @ssl
    if ssl
      @socket = OpenSSL::SSL::Socket::Client.new(skt, context: ssl, sync_close: true, hostname: @uri.host)
    else
      @socket = skt
    end
    @socket
  end

  def send(request : Raft::RPC::Packet)
    request.to_io(socket, FM)
  end

  def read
    packet = Raft::RPC::Packet.new(socket, FM)
  end
end
