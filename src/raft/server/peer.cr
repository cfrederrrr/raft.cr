class Raft::Server::Peer
  getter address : String
  @ssl : OpenSSL::SSL::Context?
  @uri : URI
  @socket : IO::Buffered? = nil

  def initialize(@address : String, @ssl : OpenSSL::SSL::Context? = nil)
    @uri = URI.parse(string)
    @socket = nil
  end

  def socket
    skt = @socket
    skt = TCPSocket.new(@uri.host, @uri.port)
    if @ssl
      skt = OpenSSL::SSL::Socket::Client.new(skt, )
  end

  def read_packet(io : IO)
    kind = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    case kind
    when Raft::RPC::AppendEntries::IDENTIFIER
      return Raft::RPC::AppendEnties(E).new(io)
    when Raft::RPC::RequestVote::IDENTIFIER
      return Raft::RPC::RequestVote.new(io)
    when Raft::RPC::AppendEntries::Result::IDENTIFIER
      return Raft::RPC::AppendEntries::Result.new(io)
    when Raft::RPC::RequestVote::Result::IDENTIFIER
      return Raft::RPC::RequestVote::Result.new(io)
    else
      raise "invalid kind"
    end
  end

end
