require "./binary"

abstract class Raft::Packet
  abstract def to_io(io : IO, fm : IO::ByteFormat)

  def self.from_io(io : IO, fm : IO::ByteFormat)
    version = Version.from_io(io, fm)
    raise Version::Mismatch.new(version) unless version.safe?

    tnum = io.read_bytes(Int16, fm)
    if tnum == AppendEntries::TNUM
      AppendEntries.from_io(io, fm)
    elsif tnum == AppendEntriesResult::TNUM
      AppendEntriesResult.from_io(io, fm)
    elsif tnum == RequestVote::TNUM
      RequestVote.from_io(io, fm)
    elsif tnum == Ballot::TNUM
      Ballot.from_io(io, fm)
    elsif tnum == Hello::TNUM
      Hello.from_io(io, fm)
    elsif tnum == GoodBye::TNUM
      GoodBye.from_io(io, fm)
    else
      raise Error.new("unknown packet type (0x#{tnum.to_s(16)})")
    end
  end
end

class Raft::Packet::Error < Exception
end
