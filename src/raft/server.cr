require "socket"
require "openssl"

class Raft::Service
  class Listener
  end
end

class Raft::Server
  # ID is always a random int64
  getter id : Int64

  # The address peers will use to connect to this server
  @peer_listener : Listener

  # The address clients will use to access the service
  @serv_listener : Service::Listener

  # Peers to this cluster
  getter peers : Array(Peer) = [] of Peer

  # The peer this `Raft::Server` is following
  getter following : Int64

  # Timeout is the time in milliseconds to wait for the leader before
  # initiating an election
  setter running : Bool

  getter config : Config

  @state : State
  @log : Log = Log.new

  # Sets the address peers will use to connect to this server
  # and restarts the listener on the new address, unless it is
  # the same address
  def peer_addr=(s : String)
    host, port = s.split(':', 2) rescue raise("invalid service address #{s}")
    @peer_addr = self.peer_addr = Socket::IPAddress.new(host, port.to_i)
  end

  # Sets the address peers will use to connect to this server
  # and restarts the listener on the new address, unless it is
  # the same address
  def peer_addr=(addr : Socket::IPAddress)
    requires_restart = @peer_addr != addr
    @peer_addr = addr
    if requires_restart
      #
      # TODO: This needs to have a way of gracefully stopping
      # connections
      #
      @peer_listener = Listener.new(@peer_addr)
    end

    return @peer_addr
  end

  # Sets the service address. If `addr` is different from `@serv_addr`,
  # this will restart the `@serv_listener` on the new address
  def serv_addr=(s : String)
    host, port = s.split(':', 2) rescue raise("invalid raft address #{s}")
    self.serv_addr = Socket::IPAddr.new(host, port.to_i)
  end

  # Sets the service address. If `addr` is different from `@serv_addr`,
  # this will restart the `@serv_listener` on the new address
  def serv_addr=(addr : Socket::IPAddress) : Socket::IPAddress
    requires_restart = @serv_addr != addr
    @serv_addr = addr
    if requires_restart
      #
      # TODO: gracefully handle finishing serving
      # clients before replacing the service listener
      #
      @serv_listener = Service::Listener.new(@serv_addr)
    end

    return @serv_addr
  end

  def timeout=(milliseconds : Int) : Time::Span
    @timeout = Time::Span.new(nanoseconds: milliseconds * 1_000_000)
    @peers.each &.timeout = @timeout
  end

  def self.new(
      paddr : String,
      saddr : String,
      state : State,
      timeout : Int32 = 300
    )
    phost, pport = s.split(':', 2) rescue raise "invalid peering address #{s}"
    shost, sport = s.split(':', 2) rescue raise "invalid service address #{s}"
    peer_addr = Socket::IPAddress.new(phost, pport)
    serv_addr = Socket::IPAddress.new(shost, sport)
    new peer_addr, serv_addr, state, timeout
  end

  def initialize(@config, @state)
    @peer_listener = Listener.new(@config.peer_addr)
    @serv_listener = Service::Listener.new(@config.serv_addr)
    @following = @id = Random.rand(Int64::Min..Int64::MAX)
    @peers = [] of Peer
    @running = false
  end

  def start
    while running?

    end
  end

  def replicate_entries
    # static values for all packets
    current_term = @state.term
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
      term:          @state.term,
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
