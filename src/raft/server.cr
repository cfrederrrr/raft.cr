require "socket"
require "openssl"
require "./state-machine"
require "./config"

# Provides several functions:
# - Orchestrates cluster membership via `Raft::Cluster` and service
# provisions via `Raft::Service`
# - Contains the consensus module
# (see [Figure 1](https://raft.github.io/raft.pdf)
# )
# - Contains and maintains the `Raft::StateMachine`
#
# ### Example:
#
# ```
# require "raft"
#
# class Position < Raft::StateMachine
#   property x : Int64 = 0_u64
#   property y : Int64 = 0_u64
#   property z : Int64 = 0_u64
# end
#
# config = Raft::Server::Config.load_ini("/path/to/config.ini")
# server = Raft::Server.new(config, Position.new)
# ```
class Raft::Server

  # Indicates the state of the server and control some processes
  enum State
    Stopped
    Starting
    Joined
    Running
    Leading
  end

  # ID is always a random int64
  getter id : Int64

  getter term : UInt64 = 0_u64

  # The address peers will use to connect to this server
  @cluster : Listener

  # The address clients will use to access the service
  @service : Listener

  # Peers to this cluster
  getter peers : Array(Peer) = [] of Peer

  # The peer this `Raft::Server` is following
  getter following : Int64

  # Timeout is the time in milliseconds to wait for the leader before
  # initiating an election
  @state : State

  getter config : Config

  @fsm : StateMachine
  @log : Log = Log.new

  def initialize(@config, @fsm)
    @cluster = Listener.new(@config.cluster)
    @service = Service.new(@config.service)
    @following = @id = Random.rand(Int64::Min..Int64::MAX)
    @peers = [] of Peer
    @state = State::Stopped
  end

  def join_cluster : State
    # send handshake to known peers right away
    @peers.each do |peer|
      handshake = Hello.new(@id)
      peer.send(handshake)
    end

    # then check config for other expected peers
    @config.peers.each do |addr|
      peer = Peer.new(addr, @config.tls)
      @peers.push(peer) if result.ok?
    end

    @peers.each do |peer|
      spawn do
        handshake = Hello.new(@id)
        result = peer.send handshake
      end
    end

    @peers.each do |peer|
      spawn do
        result = peer.read(@config.heartbeat * 2)
        if result.is_a?(Hello)
        else
        end
      end
    end

    return State::Joined
  end

  def leave_cluster : State
    stop_service
  end

  def start_service
    return State::Running
  end

  def stop_service
  end

  def participate(with channel : Channel(Bool)) : Bool
    spawn do
      while @state.running?
        @peers.each do |peer|
          entries = @log.entries[peer.commit_index..@log.commit_index]
        end
      end
    end

    channel.send(true)
    return true
  end

  def launch
    timeout_switch = Channel(Bool).new
    @state = State::Starting
    @state = join_cluster
    @state = start_service

    if @state < State::Joined
      @state = State::Stopped
      return @state
    end

    spawn do
      while participating?
        partitipate(with: timeout_switch)
        timed_out = timeout_switch.receive
        if timed_out
          election = campaign
          @state = State::LEADING if election.won?
        end
      end
    end

    return @state
  end

  def replicate_entries
    # static values for all packets
    current_term = @term
    leader_commit = @log.commit_idx
    prev_log_idx = @log.prev_log_idx
    prev_log_term = @log.prev_log_term

    @peers.each do |peer|
      # don't block on sends
      spawn do
        entries = @log[peer.commit_index..@log.commit_index]
        # find out the difference between this peer's log
        # and our log, then add them to `entries`

        pkt = RPC::AppendEntries.new(
          term:          current_term,
          leader_id:     @id,
          leader_commit: leader_commit,
          prev_log_idx:  prev_log_idx,
          prev_log_term: prev_log_term,
          entries:       entries
        )

        # might be wise to clear whatever is possibly
        # in the buffer here, but that might be something to handle
        # within Raft::Peer#send instead
        peer.send(pkt)
      end
    end

    # don't block on reads either
    @peers.each do |peer|
      spawn do
        result = peer.read

        # handle the result types
        #
        # probably just throw away anything that isn't
        # a Raft::RPC::AppendEntresResult
        #
        # possibly vote "no" if the incoming packet is
        # a Raft::RPC::RequestVote
      end
    end
  end

  def campaign
    pkt = RPC::RequestVote.new(
      term:          @term,
      candidate_id:  @id,
      last_log_idx:  @log.last_log_idx,
      last_log_term: @log.last_log_term
    )

    # don't block on sends
    @peers.each do |peer|
      spawn do
        # again, might be wise to clear whatever's in the buffer
        peer.send(pkt)
      end
    end

    # don't block on reads either
    @peers.each do |peer|
      spawn do
        result = peer.read

        # handle the result types
        #
        # if the incoming type is anything other than Raft::RPC::RequestVoteResult
        # we should probably just throw it away, since the only other possibility
        # should be Raft::RPC::AppendEntries, at which time we have lost the campaign
        # and should just wait for the leader to send another one.
        #
        # it may be possible to optimise later to enable #campaign to respond to the
        # Raft::RPC::AppendEntries, then check again for a vote result
        # but that seems like we might never escape this method
      end
    end
  end

  def participating?
    @state >= State::Joined
  end
end
