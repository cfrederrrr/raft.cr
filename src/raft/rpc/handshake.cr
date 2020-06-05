# Introduces a `Raft::Server` to another server (recognized locally
# as a `Raft::Peer`) so that they can add eachother to their peers list
#
# A handshake will occur every time a server connects to another,
# including after restarts, network timeouts, etc.
#
# Critically, a handshake packet is for a clean opening of the underlying,
# persistent TCP/SSL connection, but also carries the ID of the server
# since ID is unique per runtime
#
# No other transaction can occur between servers until the handshake
# is successful. Luckily, it is rather simple to complete, as it is
# nothing more than sharing `Raft::Version` and `Raft::Server#id`
class Raft::RPC::Hello < Raft::Packet
  #:nodoc:
  TNUM = 0x01_i16

  # TNUM of the server initiating the handshake
  getter id : Int64

  # The current term
  getter term : UInt64

  # The commit index of the server sending the packet
  getter commit_index : UInt64 = 0_u64

  # The ID of the server that the sender is leader_id
  #
  # This may be the same as `@id`
  getter leader_id : Int64

  def initialize(@id, @leader_id, @term, @commit_index)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat)
    id = io.read_bytes(UInt32, fm)
    term = io.read_bytes(UInt64, fm)
    commit_index = io.read_bytes(UInt64, fm)
    leader_id = io.read_bytes(Int64, fm)
    new id, term, commit_index, leader_id
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    Version.to_io(io, fm)
    TNUM.to_io(io, fm)
    @id.to_io(io, fm)
    @term.to_io(io, fm)
    @commit_index.to_io(io, fm)
    @leader_id.to_io(io, fm)
  end
end

class Raft::RPC::GoodBye < Raft::Packet
  TNUM = -0x01_i16
  getter id : Int64

  def initialize(@id)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat)
    id = io.read_bytes(UInt64, fm)
    new id
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    Version.to_io(io, fm)
    TNUM.to_io(io, fm)
    @id.to_io(io, fm)
  end
end
