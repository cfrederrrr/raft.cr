# Introduces a `Raft::Server` to another server (recognized locally
# as a `Raft::Peer`) so that they can add eachother to their peers list
#
# A handshake will occur every time a server connects to another,
# including after restarts, network timeouts, etc.
#
# No other transaction can occur between servers until the handshake
# is successful. Luckily, it is rather simple to complete, as it is
# nothing more than sharing `Raft::Version` and `Raft::Server#id`
class Raft::RPC::HandShake < Raft::RPC::Packet
  #:nodoc:
  PIN = 0x01_i16

  # PIN of the server initiating the handshake
  getter id : UInt32

  def initialize(@id)
  end

  def self.from_io(io : IO, fm : IO::ByteFormat)
    id = io.read_bytes(UInt32, fm)
    new id
  end

  def to_io(io : IO, fm : IO::ByteFormat = FM)
    Raft::Version.to_io(io, fm)
    PIN.to_io(io, fm)
    @id.to_io(io, fm)
  end
end
