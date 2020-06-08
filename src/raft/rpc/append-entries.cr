class Raft::RPC::AppendEntries < Raft::Packet
  # :nodoc:
  TNUM = 0xAE_i16

  # The term of the sender
  getter term : UInt32

  # The id of the leader, supplied so followers can redirect clients
  getter leader_id : Int64

  # The commit index of the leader's log
  getter leader_commit : UInt32

  # The index of the log entry immediately preceding the entries being supplied
  getter prev_log_idx : UInt32

  # 
  getter prev_log_term : UInt32

  #
  getter entries : Array(Log::Entry)

  def self.new(io : IO, fm : IO::ByteFormat)
    from_io(io, fm)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat)
    term = io.read_bytes(UInt32, fm)
    leader_id = io.read_bytes(Int64, fm)
    leader_commit = io.read_bytes(UInt32, fm)
    prev_log_idx = io.read_bytes(UInt32, fm)
    prev_log_term = io.read_bytes(UInt32, fm)

    size = io.read_bytes(UInt8, fm)
    count = 0
    entries = [] of Log::Entry

    while count < size
      entries.push Log::Entry.from_io(io, fm)
      rs = io.read_bytes(UInt8, io)
      raise "expected 0x1E but found #{rs}" if rs != SEP
      count += 1
    end

    new term, leader_id, prev_log_idx, prev_log_term, leader_commit, entries
  end

  def self.read_entry(io : IO, fm : IO::ByteFormat)
  end

  def initialize(
      @term,
      @leader_id,
      @leader_commit,
      @prev_log_idx,
      @prev_log_term,
      @entries
    )
  end

  def to_io
    io = IO::Memory.new
    to_io(io, FM)
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    Version.to_io(io, fm)
    TNUM.to_io(io, fm)
    @term.to_io(io, fm)
    @leader_id.to_io(io, fm)
    @leader_commit.to_io(io, fm)
    @prev_log_idx.to_io(io, fm)
    @prev_log_term.to_io(io, fm)
    UInt8.new(@entries.size).to_io(io, fm)
    @entries.each do |entry|
      entry.to_io(io, fm)
      SEP.to_io(io, fm)
    end
  end
end

class Raft::RPC::AppendEntriesResult < Raft::Packet
  #:nodoc:
  TNUM = -0xAE_i16

  #
  getter term : UInt32

  #
  getter success : Bool

  def self.new(io : IO, fm : IO::ByteFormat)
    from_io(io, fm)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat)
    term = io.read_bytes(UInt32, fm)
    success_val = io.read_bytes(UInt8, fm)
    success = success_val == ACK
    new term, success
  end

  def initialize(@term, @success)
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    Raft::Version.to_io(io, fm)
    TNUM.to_io(io, fm)
    @term.to_io(io, fm)
    @success ? ACK.to_io(io, fm) : NAK.to_io(io, fm)
  end
end
