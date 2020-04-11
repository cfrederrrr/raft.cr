class Raft::RPC::RequestVote < Raft::RPC::Packet
  #:nodoc:
  PIN = 0xF9_i16

  # The term associated with this RequestVote RPC
  getter term : UInt32

  # The PIN of the candidate campaigning to become leader of the cluster
  getter candidate_id : Int64

  # Index of the candidate's last log entry.
  # If the receiver's `@last_log_idx` is greater than the one associated
  # with this RequestVote RPC, the vote will not be granted.
  getter last_log_idx : UInt32

  # The term associated with the candidate's last log entry.
  # If the receiver's `@last_log_term` is greater tahn the one associated
  # with this RequestVote RPC, the vote will be denied.
  getter last_log_term : UInt32

  #
  def self.new(io : IO)
    from_io(io, FM)
  end

  # Reads a `RequestVote` packet directly from an `IO`, starting _after_
  # the `PIN` part of the packet; that is, `PIN` is only
  # present in the packet so that the socket knows what to expect when
  # reading from the `IO`
  def self.from_io(io : IO, fm : IO::ByteFormat = FM)
    term = io.read_bytes(UInt32, fm)
    candidate_id = io.read_bytes(Int64, fm)
    last_log_idx = io.read_bytes(UInt32, fm)
    last_log_term = io.read_bytes(UInt32, fm)
    endoftext = io.read_bytes(UInt8, fm)
    if io.pos == io.buffer_size
      new term, candidate_id, last_log_idx, last_log_term
    else
      raise "expected EOT char, not #{endoftext}"
    end
  end

  def initialize(@term, @candidate_id, @last_log_idx, @last_log_term)
  end

  def to_io
    io = IO::Memory.new
    to_io(io, FM)
  end

  def to_io(io : IO, fm : IO::ByteFM = FM)
    Raft::Version.to_io(io, fm)
    PIN.to_io(io, fm)
    @term.to_io(io, fm)
    @candidate_id.to_io(io, fm)
    @last_log_idx.to_io(io, fm)
    @last_log_term.to_io(io, fm)
    return io
  end
end

class Raft::RPC::RequestVote::Result < Raft::RPC::Packet
  #:nodoc:
  PIN = -0xF9_i16

  # The term associated with this RequestVote RPC
  getter term : Int32

  # Indicates whether or not the vote was granted to the candidate
  getter vote_granted : Bool

  def initialize(@term, @vote_granted)
  end

  def self.new(io : IO)
    from_io(io)
  end

  # Reads a `RequestVote::Result` directly from an `IO` starting _after_
  # the `PIN`
  def self.from_io(io : IO)
    term = io.read_bytes(UInt32, fm)
    vote_granted = io.read_bytes(UInt32, FM)
    new term, (vote_granted == ACK)
  end

  def to_io
    io = IO::Memory.new
    to_io(io, FM)
  end

  def to_io(io : IO, fm : IO::ByteFM = FM)
    Raft::Version.to_io(io, fm)
    PIN.to_io(io, fm)
    @term.to_io(io, fm)
    @vote_granted ? ACK.to_io(io, fm) : NAK.to_io(io, fm)
    return io
  end
end
