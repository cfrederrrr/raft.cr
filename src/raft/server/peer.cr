class Raft::Server::Peer
  getter address : String
  @ssl : OpenSSL::SSL::Context?
  @uri : URI
  @socket : IO::Buffered|OpenSSL::SSL::Socket::Client?

  def initialize(@address : String, @ssl : OpenSSL::SSL::Context? = nil)
    @uri = URI.parse(string)
    @socket = nil
  end

  def socket
    return @socket if @socket && !@socket.closed?
    skt = TCPSocket.new(@uri.host, @uri.port)
    if @ssl
      @socket = OpenSSL::SSL::Socket::Client.new(skt, context: @ssl, sync_close: true, hostname: @uri.host)
    else
      @socket = skt
    end
    @socket
  end

  def request_vote(request)
    request.to_io(socket, FM)
    Fiber.yield
    Raft::RPC::RequestVote::Result.new(socket, FM)
  end
end
