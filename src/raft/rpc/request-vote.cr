struct Raft::RPC::RequestVote < Raft::RPC::NetComm
  getter term : UInt32
  getter candidate_id : UInt32
  getter last_log_idx : UInt32
  getter last_log_term : UInt32

  def self.new(io : IO)
    from_io(io)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat = FM)
    term = io.read_bytes(UInt32, fm)
    candidate_id = io.read_bytes(UInt32, fm)
    last_log_idx = io.read_bytes(UInt32, fm)
    last_log_term = io.read_bytes(UInt32, fm)
    new term, candidate_id, last_log_idx, last_log_term
  end

  def initialize(@term, @candidate_id, @last_log_idx, @last_log_term)
  end

  def to_io
    io = IO::Memory.new(160)
    to_io(io, FM)
  end

  # RequestVote packet structure
  #
  # ```
  #  <--         32 bits          -->
  # +--------------------------------+
  # | Type indication (0x0000ff00)   |
  # +--------------------------------+
  # | Candidate ID                   |
  # +--------------------------------+
  # |                                |
  # +--------------------------------+
  # |                                |
  # +--------------------------------+
  # ```
  def to_io(io : IO, fm : IO::ByteFormat = FM)
    0x0000ff00_u32.to_io(io, fm)
    Raft::Version.to_io(io, fm)
    @term.to_io(io, fm)
    @candidate_id.to_io(io, fm)
    @last_log_idx.to_io(io, fm)
    @last_log_term.to_io(io, fm)
    return io
  end
end

struct Raft::RPC::RequestVote::Result < Raft::RPC::NetComm
  IDENTITY = 0x0000ff00_u32
  getter term : Int32
  getter vote_granted : Bool

  def self.new(io : IO)
    from_io(io)
  end

  def self.from_io(io : IO)
    term = io.read_bytes(UInt32, fm)
    vote_granted = io.read_bytes(UInt32, FM)
    if vote_granted == 0xffff000_u32
      return new(term, true)
    elsif vote_granted == 0x0000ffff_u32
      return new(term, false)
    else
      raise "cannot determine success/failure of vote"
    end
  end

  def initialize(@term, @vote_granted)
  end

  def to_io
    io = IO::Memory.new(32*3)
    to_io(io, FM)
  end

  def to_io(io : IO, fm : IO::ByteFormat = FM)
    IDENTITY.to_io(io, fm)
    @term.to_io(io, fm)
    (@vote_granted ? 0xffff0000_u32 : 0x0000ffff_u32).to_io(io, fm)
    return io
  end
end
