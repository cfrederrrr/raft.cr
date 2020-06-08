# Stores the entries and manages consensus
class Raft::Log
  getter commit_index : UInt64 = 0_u64

  getter term : UInt64 = 0_u64

  @entries : Array(Entry) = [] of Entry

  def self.from_io(io : IO, fm : IO::ByteFormat)
    entries = [] of Entry
    while io.peek.any?
      typeid = io.read_bytes(Int32, fm)
      {% begin %}
        {% ids = {} of Nil => Nil %}
      case typeid
        {% for t in Entry.all_subclasses %}
          {% typeid = t.constant(:TNUM) %}
          {% if ! tnum.is_a?(NumberLiteral) %}
            {% raise "#{t.id}::TNUM must be Int32" %}
          {% elsif tnum > Int32::MAX || tnum < Int32::MIN %}
            {% raise "#{t.id}::TNUM must be Int32"%}
          {% end %}
          {% if ids.keys.includes?(typeid) %}
            {% raise "#{t.id} can't have the same TNUM as #{ids[typeid]}" %}
          {% else %}
            {% ids[typeid] = t %}
          {% end %}
      when {{t}}::TNUM then entries.push {{t.id}}.from_io(io, fm)
        {% end %}
      end
      {% end %}
    end

    new entries
  end

  def initialize(@entries : Array(Entry))
    @term = @entries.empty? ? 0_u64 : @entries.last.term
  end

  def append(entry : Entry)

  end

  def to_io(io : IO, fm : IO::ByteFormat)
    @entries.each do |entry|
      entry.to_io(io, fm)
    end
  end

end

class Raft::Log::Entry
  # The term associated with this entry
  getter term : UInt64

  # The actual contents used to update `Raft::Server`'s `@fsm`
  getter update : Update

  def self.from_io(io : IO, fm : IO::ByteFormat)
    term = io.read_bytes(UInt64, fm)
    update = Update.from_io(io, fm)
    new term, update
  end

  def initialize(@term, @update)
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    @term.to_io(io, fm)
    @update.to_io(io, fm)
  end
end

# `TNUM` must be defined and it must be `Int32`
abstract class Raft::Log::Update
  abstract def iobody(io : IO, fm : IO::ByteFormat)
  abstract def from_io(io : IO, fm : IO::ByteFormat)

  macro inherited
    def self.from_io(io : IO, fm : IO::ByteFormat)
      from_io(io, fm)
    end

    def to_io(io : IO, fm : IO::ByteFormat)
      {{@type}}::TNUM.to_io(io, fm)
      iobody(io, fm)
    end
  end
end
