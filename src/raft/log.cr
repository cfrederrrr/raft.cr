class Raft::Log
  @entries : Array(Raft::Log::Entry)

  def to_io(io : IO, fm : IO::ByteFormat)
    @entries.each do |entry|
      entry.to_io(io, fm)
    end
  end

  def initialize(@entries : Array(Raft::Log::Entry))
  end

  def self.from_io(io : IO::Buffered, fm : IO::ByteFormat = IO::ByteFormat::NetworkEndian)
    entries = [] of Raft::Log::Entry
    while io.peek.any?
      typeid = io.read_bytes(Int32, fm)
      {% begin %}
      case typeid
        {% for t in Raft::Log::Entry.all_subclasses %}
      when {{t}}::TYPEID then entries.push {{t.id}}.from_io(io, fm)
        {% end %}
      end
      {% end %}
    end

    new entries
  end
end

abstract class Raft::Log::Entry
  abstract def to_io(io : IO, fm : IO::ByteFormat)
  abstract def from_io(io : IO, fm : IO::ByteFormat)
end
