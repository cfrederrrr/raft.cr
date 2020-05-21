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
  enum Status
    Stopped
    Starting
    Joined
    Following
    Leading

    def partiticipating?
      self >= Joined
    end
  end

  delegate stopped?, to: @membership
  delegate starting?, to: @membership
  delegate joined?, to: @membership
  delegate partiticipating?, to: @membership
  delegate running?, to: @membership

  def leading?
    @following == @id
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
  @membership : Status

  getter config : Config

  @fsm : StateMachine
  @log : Log = Log.new

  def initialize(@config, @fsm)
    @cluster = Listener.new(@config.cluster, @config.tls)
    @service = Listener.new(@config.service, @config.tls)
    @following = @id = Random.rand(Int64::Min..Int64::MAX)
    @peers = [] of Peer
    @membership = Status::Stopped
  end

  def start
    launch
    while running?
      handle_clients # handle clients should spawn a while loop that responds
                     # to requesters (i.e. non-cluster members)
                     # and maybe should only break if
      leading? ? lead_cluster : follow
    end
  end

  def stop
  end

  private def launch
    @membership = Status::Starting

    # start listening for data from other servers before sending any out
    @cluster.listen
    @membership = join_cluster

    @service.listen
    @membership = start_service

    if @membership < Status::Joined
      @membership = Status::Stopped
      return @membership
    end

    spawn do
      while participating?
        partitipate
        timed_out = timeout_switch.receive
        if timed_out
          election = campaign
          @membership = Status::Leading if election.won?
        end
      end
    end

    return channels
  end

  private def join_cluster
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
      handshake = Hello.new(@id)
      result = peer.send handshake
    end

    @peers.each do |peer|
      spawn do
        result = peer.read(@config.heartbeat * 2)
        if result.is_a?(Hello)
        else
        end
      end
    end

    @membership = Status::Joined
  end

  private def leave_cluster : Status
    stop_service
  end

  private def start_service
    @membership = Status::Following
  end

  private def stop_service
  end

  private def lead_cluster
    # lead_cluster always sends and receives from peers unlike follow
    # follow still needs a way to check for packets from non-leaders
    # so that they can vote when another peer campaigns
    # or a `AppendEntries` in case the election is won before
    # the RequestVote is received.
    #
    # that might just mean that, during follow mode, for all peers except the
    # leader, we should just berunning `peer.read` with the expectation of a
    # RequestVote i.e.
    # `rv = RequestVote.new(peer, IO::ByteFormat::NetworkEndian)`
    # and let the io simply wait on that packet indefinitely in a sleeping
    # fiber

    @status = Status::Leading
    while leading?
      tick_finish = Time.local + @config.heartbeat
      # check peer states and send missing entries
      # or just send empty RPC::AppendEntries if peer state matches
      # local state
      replicate_entries

      # to prevent excessive sending of heartbeats:
      #   sleep for the remaining time of the "tick"
      #   which is the start time plus the heartbeat minus the time spent
      #   between the start time and now
      sleep tick_finish - Time.local
    end

    @status = Status::Following
  end

  private def follow(peer : Peer)
    @following = peer.id

    spawn do
      while @membership.running?
        @peers.each do |peer|
          entries = @log.entries[peer.commit_index..@log.commit_index]
        end
      end
    end

    channel.send(true)
    return true
  end

  private def participate
    @peers.each do |peer|
      spawn do
        packet = peer.read
        case packet
        when RPC::RequestVote
        when RPC::AppendEntries
        else
          peer.close
          @peers.delete(peer)
        end
      end
    end
  end

  # Requests come in the form of `Packet`s.
  # - UpdateState
  # - GetState
  # - StopServer
  # - StartServer
  # - responses to all of the above
  private def handle_requests
    requests = [] of Packet

    @service.connections.each do |socket|
      request = Packet.new(socket, IO::ByteFormat::NetworkEndian)
      requests.push(request)
    end



    return requests
  end

  private def replicate_entries
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

  private def campaign
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
end
