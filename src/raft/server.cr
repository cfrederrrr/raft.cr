require "socket"
require "openssl"

class Raft::Server
  @port : UInt16 = 4290_u16
  @peers : Array(Raft::Server::Peer) = [] of Raft::Server::Peer
  @leader : Bool = false

  def initialize(init_state : T) forall T
    @port = 4290_u8
    @peers = [] of Raft::Server
    @leader = false
    @state = Raft::State(T)
  end

  def initialize(@port = 4290_u16, @leader = false, @peers = [] of Raft::Server::Peer)
  end

  def read_packet(io : IO)
    kind = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    case kind
    when 0xffff0000
      return Raft::RPC::AppendEnties(E).new(io)
    when 0xf0f0f0f0
      return Raft::RPC::RequestVote.new(io)
    else
      raise "invalid kind"
    end
  end
end

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
  end
end

require "./server/plain"
require "./server/ssl"
