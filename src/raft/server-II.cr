require "socket"
require "openssl"

class Raft::Server

  # ID is always a random int64
  getter id : Int64
  getter paddr : Socket::IPAddress
  def paddr=(s : String)
    begin
      host, port = s.split(':', 2)
    rescue
      raise "invalid tcp address #{s} - must be <ip>:<port>"
    end

    @paddr = Socket::IPAddr.new(host, port.to_i)
  end

  getter aaddr : Socket::IPAddress
  def aaddr=(s : String)
    begin
      host, port = s.split(':', 2)
    rescue
      raise "invalid tcp address #{s} - must be <ip>:<port>"
    end

    @aaddr = Socket::IPAddr.new(host, port.to_i)
  end

  getter peers : Array(Peer)

  # The peer this `Raft::Server` is following
  getter following : Int64

  # Timeout is the time in milliseconds to wait for the leader before
  # initiating an election
  getter timeout : Float32
  def timeout=(n : Int) : Float32
    @timeout = n / 1000_f32
  end

  def initialize(
      paddr : String,
      aaddr : String,
      timeout : Int32 = 300
      @peers = [] of Peer,
    )

    @following = @id = Random.rand(Int64::MIN..INT64::MAX)

    self.paddr = paddr
    self.aaddr = aaddr
    self.timeout = timeout

    @peers.each{ |peer| peer.timeout = @timeout }
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
        entries = [] of Raft::Log::Entry
        # find out the difference between this peer's log
        # and our log, then add them to `entries`

        pkt = Raft::RPC::AppendEntries.new(
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
    pkt = Raft::RPC::RequestVote.new(
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
