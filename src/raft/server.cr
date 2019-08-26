require "socket"
require "openssl"

class Raft::Server
  @id : UInt64
  @port : UInt16 = 4290_u16
  @peers : Array(Raft::Server::Peer) = [] of Raft::Server::Peer
  @leader : Bool = false
  @following : UInt64? = nil

  def initialize(init_state : T) forall T
    @id = Random.rand(UInt64::MAX)
    @port = 4290_u16
    @following = nil
    @peers = [] of Raft::Server::Peer
  end

  def initialize(
      @id = Random.rand(UInt64::Max),
      @port = 4290_u16,
      @leader = false,
      @following = nil,
      @peers = [] of Raft::Server::Peer
    )
  end

  def request_vote
    request = Raft::RPC::RequestVote.new(@term, @id, @state.last_log_idx, @state.last_log_term)
    @peers.each do |peer|
      peer.request_vote(request)
    end
  end

  def append_entries(entries : Log)
    request = Raft::RPC::AppendEntries.new(@term, @id, @state.last_log_idx)
  end

end

require "./server/peer"
