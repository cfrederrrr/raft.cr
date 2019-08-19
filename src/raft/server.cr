require "socket"
require "openssl"

class Raft::Server
  @id : UInt64
  @port : UInt16 = 4290_u16
  @peers : Array(Raft::Server::Peer) = [] of Raft::Server::Peer
  @leader : Bool = false

  def initialize(init_state : T) forall T
    @id = Random.rand(UInt64::MAX)
    @port = 4290_u8
    @leader = false
    @peers = [] of Raft::Server::Peer
  end

  def initialize(@port = 4290_u16, @leader = false, @peers = [] of Raft::Server::Peer)
  end

  def request_vote
    @peers.each do |peer|
      peer.request_vote(@state.term, @state.log)
    end
  end

end

require "./server/peer"
