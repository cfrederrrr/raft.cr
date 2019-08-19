struct Raft::RPC::AppendEnties(E) < Raft::RPC::NetComm
  # Size of the header before the data section
  HEADER_SIZE = 32 * 6

  IDENTIFIER = 0xAE00_u16
  getter term : UInt32
  getter leader_id : UInt32
  getter leader_commit : UInt32
  getter prev_log_idx : UInt32
  getter prev_log_term : UInt32
  getter entries : Array(E)

  def self.new(io : IO, fm : IO::ByteFormat = Format)
    from_io(io, fm)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat = Format)
    term = io.read_bytes(UInt32, bf)
    leader_id = io.read_bytes(UInt32, bf)
    leader_commit = io.read_bytes(UInt32, bf)
    prev_log_idx = io.read_bytes(UInt32, bf)
    prev_log_term = io.read_bytes(UInt32, bf)
    entries = [] of E
    while io.pos < io.bytesize
    new term, leader_id, prev_log_idx, prev_log_term, leader_commit, entries
  end

  def self.read_entry(io : IO, fm : IO::ByteFormat = Format)
  end

  def initialize(
      @term : UInt32,
      @leader_id : UInt32,
      @leader_commit : UInt32,
      @prev_log_idx : UInt32,
      @prev_log_term : UInt32,
      @entries : Array(E)
    )
  end

  def to_io
    io = IO::Memory.new
    to_io(io, Format)
  end

  # AppendEntries packet structure
  #
  #```text
  #  <--         32 bits          -->
  # +--------------------------------+
  # | Type indication (0xff000000)   |
  # +--------------------------------+
  # | Log Type Indicator             |
  # |                                |
  # +--------------------------------+
  # | Term                           |
  # +--------------------------------+
  # | Leader ID                      |
  # +--------------------------------+
  # | Leader Commit                  |
  # +--------------------------------+
  # | Previous Log Term              |
  # +--------------------------------+
  # | Previous Log Index             |
  # +--------------------------------+
  # | Entries ...
  # ```
  #
  def to_io(io : IO, fm : IO::ByteFormat = Format)
    ::Raft::Version.to_io(io, fm)
    IDENTIFIER.to_io(io, fm)
    @term.to_io(io, fm)
    @leader_id.to_io(io, fm)
    @leader_commit.to_io(io, fm)
    @prev_log_idx.to_io(io, fm)
    @prev_log_term.to_io(io, fm)
    @entries.each do |entry|
      entry.to_io(io, fm)
      RS.to_io(io, fm)
    end
    EOT.to_io(io, fm)
  end
end

struct Raft::RPC::AppendEntries::Result < Raft::RPC::NetComm
  IDENTIFIER = 0xAEF0_u16

  getter term : UInt32
  getter success : Bool

  def self.new(io : IO, fm : IO::ByteFormat = Format)
    from_io(io, fm)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat = Format)
    term = io.read_bytes(UInt32, fm)
    success_val = io.read_bytes(UInt8, fm)
    success = success_val == ACK ? true : false
    new term, success
  end

  def initialize(@term, @success)
  end

  # AppendEntries packet structure
  #
  # ```text
  #  <--         32 bits          -->
  # +--------------------------------+
  # | Type indication (0xff000000)   |
  # +--------------------------------+
  # | Term                           |
  # +--------------------------------+
  # | Success                        |
  # +--------------------------------+
  # ```
  def to_io(io : IO, fm : IO::ByteFormat = Format)
    ::Raft::Version.to_io(io, fm)
    IDENTIFIER.to_io(io, fm)
    @term.to_io(io, fm)
    @success ? ACK.to_io(io, fm) : NAK.to_io(io, fm)
    EOT.to_io(io, fm)
  end
end
