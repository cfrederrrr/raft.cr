class Raft::Log
  @entries : Array(Raft::Log::Entry)

  def self.from_io(io : IO, fm : IO::ByteFormat)
    entries = [] of Raft::Log::Entry
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    @entries.each do |entry|
      entry.to_io(io, fm)
    end
  end

  def initialize(@entries : Array(Raft::Log::Entry))
  end
end

abstract class Raft::Log::Entry
  abstract def to_io(io : IO, fm : IO::ByteFormat) : IO
  abstract def from_io(io : IO, fm : IO::ByteFormat)
  abstract def class_id : UInt64
end
