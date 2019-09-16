require "socket"
require "openssl"

class Raft::Server
  include Follower
  include Leader


  alias FM = IO::ByteFormat::NetworkEndian
  alias Packet = Raft::RPC::Packet
  alias RequestVote = Raft::RPC::RequestVote
  alias AppendEntries = Raft::RPC::AppendEntries

  # The ID number of the server. Used in communication so that
  # peers know who is sending messages
  @id : Int64 = Random.rand(Int64::MIN..Int64::MAX)

  # The port to listen for raft communications on
  @port : UInt16 = 4290

  # List of remote peer `Raft::Server`s in the cluster
  @peers : Array(Raft::Server::Peer) = {} of Int64 => Raft::Server::Peer

  # True if this `Raft::Server` is leading
  @leader : Bool = false

  # The `@id` of the leading server or `nil` if this `Raft::Server` is leading
  @following : Int64? = nil

  # Election timeout in milliseconds. The `Raft::Server` will initiate an
  # election if this timeout is reached
  getter timeout : Int32

  @state : Raft::State = Raft::State.new

  delegate last_log_idx, last_log_term, to: @state

  def initialize(@port = 4290_u16, @timeout : Int32)
  end

  def start
    # this part is still wip
    # much, if not all of this will change after i figure out what i want to do here.
    loop do
      campaign do
        become_leader
        lead
      end

      await_election do |req|
        cast_ballot vote()
      end

      follow

      # 1. check if there are any known peers
      #   a. just run if there aren't
      #   b. request vote if there are
      # 2. await results
      #   a. if granted, lead
      #   b. ifnot, wait for a leader to show itself
      # 4. if the leader shows itself, follow
      # 5. if no one appears to lead, re-assess the peers
      # 6. request vote again
    end
  end

  # Campaigns for leadership with all active peers.
  # Yields if the quorum is met and election is won.
  # Otherwise returns `nil`
  def campaign : Nil
    # this loop initiates the election.
    # we don't wait for the responses yet, as we want to send out all
    # ballots before we start tallying any of them.
    @peers.each do |id, peer|
      peer.send(RequestVote.new(@term, @id, last_log_idx, last_log_term))
    end

    # start with 1, as the vote for self
    votes = 1

    # this loop collects and tallies votes.
    # additionally, this loop can cancel the campaign at any time if
    # a peer responds with an `AppendEntries`, rather than a `RequestVote::Result`
    until votes >= quorum
      @peers.each do |id, peer|
        response = Packet.new(socket, FM)
        case response
        when RequestVote::Result
          votes += 1 if response.vote_granted
        when AppendEntries
        when AppendEntries::Result
        when RequestVote
          # always vote `false` because we have voted for ourselves
          # in our own campaign
          response = ReuqestVote::Result.new(@term, false)
          peer.send(RequestVote)
        else
        end
      end
    end
  end

  def vote(req : Raft::RPC::ReqeuestVote)
    (!@state.voted_for < null) &&
    req.term >= @state.current_term
  end

  @[AlwaysInline]
  def quorum
    @peers.size / 2 + 1
  end

  def become_leader
    @following = nil
    @leader = true
  end
end

require "./server/follower"
require "./server/leader"
require "./server/peer"
