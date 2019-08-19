struct Raft::RPC::RequestVote < Raft::RPC::NetComm
  IDENTIFIER = 0xF900_u16

  # Packet size dynamically
  PKTSIZE = (
    sizeof(IDENTIFIER.class) + # class id
    sizeof(UInt32) +           # term
    sizeof(UInt32) +           # candidate_id
    sizeof(UInt32) +           # last_log_idx
    sizeof(UInt32) +           # last_log_term
    sizeof(EOT.class)          # end of transmission control char
  )

  # The term associated with this RequestVote RPC
  getter term : UInt32

  # The ID of the candidate campaigning to become leader of the cluster
  getter candidate_id : UInt32

  # Index of the candidate's last log entry.
  # If the receiver's `@last_log_idx` is greater than the one associated
  # with this RequestVote RPC, the vote will not be granted.
  getter last_log_idx : UInt32

  # The term associated with the candidate's last log entry.
  # If the receiver's `@last_log_term` is greater tahn the one associated
  # with this RequestVote RPC, the vote will be denied.
  getter last_log_term : UInt32

  def self.new(io : IO)
    from_io(io, Format)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat = Format)
    term = io.read_bytes(UInt32, fm)
    candidate_id = io.read_bytes(UInt32, fm)
    last_log_idx = io.read_bytes(UInt32, fm)
    last_log_term = io.read_bytes(UInt32, fm)
    endoftext = io.read_bytes(UInt8, fm)
    if endoftext == EOT
      new term, candidate_id, last_log_idx, last_log_term
    else
      raise "expected EOT char, not #{endoftext}"
    end
  end

  def initialize(@term, @candidate_id, @last_log_idx, @last_log_term)
  end

  def to_io
    io = IO::Memory.new(160)
    to_io(io, Format)
  end

  def to_io(io : IO, fm : IO::ByteFormat = Format)
    IDENTIFIER.to_io(io, fm)
    Raft::Version.to_io(io, fm)
    @term.to_io(io, fm)
    @candidate_id.to_io(io, fm)
    @last_log_idx.to_io(io, fm)
    @last_log_term.to_io(io, fm)
    return io
  end
end

struct Raft::RPC::RequestVote::Result < Raft::RPC::NetComm
  IDENTIFIER = 0xF9F0_u16
  PKTSIZE = (
    sizeof(IDENTIFIER.class) + # class identifier
    sizeof(Int32) +            # term
    sizeof(ACK.class) +        # vote granted (ACK and NAK are same size)
    sizeof(EOT.class)          # end of transmittion control char
  )

  getter term : Int32
  getter vote_granted : Bool

  def initialize(@term, @vote_granted)
  end

  def self.new(io : IO)
    from_io(io)
  end

  def self.from_io(io : IO)
    term = io.read_bytes(UInt32, fm)
    vote_granted = io.read_bytes(UInt32, Format)
    case
    when vote_granted == ACK then return new(term, true)
    when vote_granted == NAK then return new(term, false)
    else raise "cannot determine success/failure of vote"
    end
  end

  def to_io
    io = IO::Memory.new(PKTSIZE)
    to_io(io, Format)
  end

  def to_io(io : IO, fm : IO::ByteFormat = Format)
    IDENTIFIER.to_io(io, fm)
    @term.to_io(io, fm)
    @vote_granted ? ACK.to_io(io, fm) : NAK.to_io(io, fm)
    EOT.to_io(io, fm)
    return io
  end
end
