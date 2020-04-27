# Stores the entries and manages consensus
class Raft::Log
  @entries : Array(Entry) = [] of Entry

  def to_io(io : IO, fm : IO::ByteFormat)
    @entries.each do |entry|
      entry.to_io(io, fm)
    end
  end

  def initialize(@entries : Array(Entry))
  end

  def self.from_io(io : IO::Buffered, fm : IO::ByteFormat = NetworkEndian)
    entries = [] of Entry
    while io.peek.any?
      typeid = io.read_bytes(Int32, fm)
      {% begin %}
        {% ids = {} of Nil => Nil %}
      case typeid
        {% for t in Entry.all_subclasses %}
          {% typeid = t.constant(:TNUM) %}
          {% if ! tnum.is_a?(NumberLiteral) || tnum > Int32::MAX || tnum < Int32::MIN %}
            {% raise "#{t}::TNUM must be Int32" %}
          {% end %}
          {% if ids.keys.includes?(typeid) %}
            {% raise "#{t.id}::TNUM (#{typeid}) cannot be the same as #{ids[typeid]}::TNUM" %}
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
end

# `TNUM` must be defined and it must be `Int32`
abstract class Raft::Log::Entry
  abstract def iobody(io : IO, fm : IO::ByteFormat)
  abstract def from_io(io : IO, fm : IO::ByteFormat)

  macro inherited
    def self.from_io(io : IO, fm : IO::ByteFormat)
      from_io(io, fm)
    end

    def to_io(io : IO, fm : IO::ByteFormat)
      {{ @type }}::TNUM.to_io(io, fm)
      iobody(io, fm)
    end
  end
end
