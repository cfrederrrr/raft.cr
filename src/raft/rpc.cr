module Raft::RPC
  # Single byte control characters, written in binary notation
  # to ensure that there are no accidental duplicates
  #
  # Many are pulled from ASCII/Unicode
  #
  # They are represented here as UInt8, as it is easier to work
  # with given the surrounding context (mainly because unicode is not
  # guaranteed to be one or two bytes).

  # [Start of Text](https:///codepoints.net/U+0002) - Used in `Packet` at the end of the
  # header section to indicate the start of the data section
  STX = 0x02_u8

  # [End of Transmission](https://codepoints.net/U+0004) - Used in `Packet` to signal the end of
  # the packet.
  EOT = 0x04_u8

  # [Acknowledge](https://codepoints.net/U+0006) - Used in `Packet` to denote boolean `true`
  ACK = 0x06_u8

  # [Not Acknowledged](https://codepoints.net/U+0015) - Used in `Packet` to denote boolean `false`
  NAK = 0x15_u8

  # [Record Separator](https://codepoints.net/U+001E) - Used in `Packet` to separate `Packet::Entry`
  RS = 0x1E_u8
end

abstract class Raft::RPC::Packet
  abstract def to_io(io : IO, fm : IO::ByteFormat)

  def self.from_io(io : IO, fm : IO::ByteFormat = PacketFormat)
    version = Raft::Version.from_io(io, fm)
    raise Raft::Version::Mismatch.new(version) unless version.safe?

    pin = io.read_bytes(Int16, fm)
    case pin
    when AppendEntries::TNUM
      AppendEntries.from_io(io, fm)
    when AppendEntriesResult::TNUM
      AppendEntriesResult.from_io(io, fm)
    when RequestVote::TNUM
      RequestVote.from_io(io, fm)
    when RequestVoteResult::TNUM
      RequestVoteResult.from_io(io, fm)
    when HandShake::TNUM
      HandShake.from_io(io, fm)
    else raise PacketError.new("invalid packet id number '#{pin}'")
    end
  end
end

class Raft::RPC::PacketError < Exception
end

require "./rpc/request-vote"
require "./rpc/append-entries"
require "./rpc/handshake"
