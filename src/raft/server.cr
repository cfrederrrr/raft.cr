require "socket"
require "openssl"

require "./log"
require "./config"
require "./state-machine"
require "./peer"

private alias TLS = OpenSSL::SSL
private alias NetworkFormat = IO::ByteFormat::NetworkEndian

# Provides several functions:
# - Orchestrates cluster membership via `Raft::Cluster` and service
# provisions via `Raft::Service`
# - Contains the consensus module
# (see [Figure 1](https://raft.github.io/raft.pdf))
#
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
  @config        : Config
  @state_machine : StateMachine
  @id            : Int64
  @log           : Log = Log.new
  @voted_for     : Int64?
  @cluster       : Listener
  @service       : Listener
  @peers         : Hash(Int64, Peer) = {} of Int64=>Peer
  @leader_id     : Int64

  # Indicates the level of presence of the server - see `Presence`
  getter presence : Presence

  enum Presence
    Stopped
    Starting
    Joined
    Following
    Leading
  end

  def leading?
    @peers.size > 0 &&
    @leader_id == @id
  end

  def initialize(@config, @state_machine)
    @cluster = Listener.new(@config.cluster, @config.tls)
    @service = Listener.new(@config.service, @config.tls)
    @leader_id = @id = Random.rand(Int64::Min..Int64::MAX)
    @peers = {} of Int64=>Peer
    @presence = Presence::Stopped
  end

  def start
    launch
    while @presence.running?
      if leading?
        @peers.each do |peer|
          entries = @log[peer.match_index..@log.commit_index]
          # i think prev_log_idx and prev_log_term refer to
          # the difference between current log number
          # and how many entries have been added since last
          packet = RPC::AppendEntries.new(
            term: @log.term,
            leader_id: @id,
            leader_commit: @log.commit_index,
            prev_log_idx: @log.prev_log_idx,
            prev_log_term: @log.prev_log_term,
            entries: entries
          )
          peer.send packet
        end

        @peers.each do |peer|
          result = peer.read # check for OK from peer
        end
      else
      end

    end
  end

  def stop
  end

  private def launch
    @presence = Presence::Starting

    # start listening for data from other servers before sending any out
    @cluster.listen
    @presence = join_cluster

    @service.listen
    @presence = start_service

    @presence = Presence::Stopped if @presence < Presence::Joined
    return @presence
  end

  private def join_cluster
    peers = {} of Int64=>Peer
    # send handshake to known peers right away
    @peers.each do |id, peer|
      hello = Hello.new(@id)
      peer.send(hello)
    end

    # then check config for other expected peers
    @config.peers.each do |addr|
      hello = Hello.new(@id, @log.term, @log.commit_index, @id)
      peer = Peer.handshake(hello)
      peers.push Peer.handshake(hello)
    end

    blocker = Channel(Hello?).new
    peers.each do |peer|
      spawn do
        result = peer.read(@config.heartbeat * 2)
        if result.is_a?(Hello)
          @peers[result.id] = peer
        else
        end
      end
    end

    peers.size.times do |t|

    end

    @presence = Presence::Joined
  end

  # Receiver implementation of handshake protocol
  private def handshake(packet : Handshake)
    peer = Peer.new(socket, result.id, result.next_index, result.match_index)
    # TODO: probably should check if the id is already occupied and the connection is open
    # could be an impersonator
    @peers[result.id] = peer
  end

  # Sender implementation of handshake protocol
  private def init_handshake(address : URI)
    socket = TCPSocket.new(address.host, address.port)
    socket.read_timeout = @config.heartbeat
    socket.write_timeout = @config.heartbeat

    if @config.tls
      ctx = TLS::Context::Client.new(@config.cafile)
      socket = TLS::Socket::Client.new(socket, ctx, true, address.host)
    end

    spawn do
      packet = Handshake::Hello.new(@id, @leader_id, @term, @log.commit_index)
      begin
        packet.to_io(socket, NetworkFormat)
        socket.flush
        result = Packet.from_io(socket, NetworkFormat)
        if result.is_a?(Handshake::Hello)
          handshake(result)
        else
          return
        end
      rescue
        # any kind of error simply means the handshake fails and we do not
        # get to add the peer to the list of peers. no reason to stop
        # the rest of the program though, so just move on and try again later
        return
      end
    end
  end

  private def leave_cluster : Presence
    stop_service
  end

  private def start_service
    @presence = Presence::Following
    while running?
      spawn do
        @service.connections.each do |conn|
          # read requests and add them to processing queue
        end
      end
    end
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

    @presence = Presence::Leading
    while leading?
      tick_finish = Time.local + @config.heartbeat
      # check peer states and send missing entries
      # or just send empty RPC::AppendEntries if peer state matches
      # local state

      #
      # - collect entries from service clients
      # - replicate the entries to peers
      # -

      replicate_entries

      # to prevent excessive sending of heartbeats:
      #   sleep for the remaining time of the "tick"
      #   which is the start time plus the heartbeat minus the time spent
      #   between the start time and now
      sleep tick_finish - Time.local
    end

    @presence = Presence::Following
  end

  private def follow(peer : Peer)
    @leader_id = peer.id

    spawn do
      while @presence.running?
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
      request = Packet.from_io(socket, NetworkFormat)
      requests.push(request)
    end

    return requests
  end

  # Enables `Raft::Server` leading its cluster to send entries to followers
  private def replicate_entries
    pconf = {
      term:          @log.term,
      leader_id:     @id,
      leader_commit: @log.commit_idx,
      prev_log_idx:  @log.prev_log_idx,
      prev_log_term: @log.prev_log_term,
      entries:       entries
    }

    @peers.each &.send(RPC::AppendEntries.new(**pconf))

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

  def update_state(entries : Array(Log::Entry)) : Int32
    entries_applied = 0

    entries.each.with_index do |entry, index|
      begin
        @state_machine.update(entry)
        @log.term = entry.term
        entries_applied += 1
      rescue
        return entries_applied
      end
    end

    return entries_applied
  end

  # Enables `Raft::Server` following a peer to receive entries and apply them
  # to the log
  private def append_entries(packet : RPC::AppendEntries) : RPC::AppendEntriesResult
    # be sure to update term and reset `@voted_for` to null if packet.term > @log.term
    return RPC::AppendEntriesResult.new(@log.term, false) if (
      packet.term < @log.term ||
      packet.prev_log_idx < @log.commit_index
    )

    # this may be an opportunity for optimization later. maybe rather than appending
    # them one by one we should apply the whole thing to the log, if possible
    # then apply the updates to the state machine if the log updates successfully (or
    # as many as were correctly applied to the log), thus saving some overhead on
    # method calls
    packet.entries.each do |entry|
      log_updated = @log.append(entry)
      sm_updated = @state_machine.update(entry) if log_updated
      if !sm_updated
        return RPC::AppendEntriesResult.new(@log.term, false)
      end
    end

  end

  # Sends a `RequestVote` to each of the peers and awaits a quorum
  #
  # Quorum can be defined in one of two ways.
  # 1. Explicitly in the configuration (`@config`)
  # 2. Implicitly by calculating the number of peers at the start of the `campaign`
  private def campaign
    pconf = {
      term: @log.term,
      candidate_id: @id,
      last_log_idx: @log.last_log_idx,
      last_log_terM: @log.last_log_term
    }

    @peers.each &.send(RPC::RequestVote.new(**pconf))

    ballot_box = Channel(Packet?).new
    @peers.each do |peer|
      result = peer.read

      # handle the result types
      #
      # if the incoming type is anything other than Raft::RPC::Ballot
      # we should probably just throw it away, since the only other possibility
      # should be Raft::RPC::AppendEntries, at which time we have lost the campaign
      # and should just wait for the leader to send another one.
      #
      # it may be possible to optimise later to enable #campaign to respond to the
      # Raft::RPC::AppendEntries, then check again for a vote result
      # but that seems like we might never escape this method
    end
  end

  private def cast_vote(candidate : RPC::RequestVote) : RPC::Ballot
    return RPC::Ballot.new(@log.term, false) if candidate.term < @log.term

    granted = false

    if @voted_for.nil? || @voted_for == candidate.id
      granted = begin
        candidate.last_log_term >= @log.term &&
        candidate.last_log_idx >= @log.commit_index
      end
    end

    return RPC::Ballot.new(@log.term, granted)
  end
end
