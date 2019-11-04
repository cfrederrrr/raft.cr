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
        {% ids = {} of Nil => Nil %}
      case typeid
        {% for t in Raft::Log::Entry.all_subclasses %}
          {% typeid = t.constant(:PIN) %}
          {% if ! typeid.is_a?(NumberLiteral) || typeid > Int32::MAX || typeid < Int32::MIN %}
            {% raise "#{t}::PIN must be Int32" %}
          {% end %}
          {% if ids.keys.includes?(typeid) %}
            {% raise "#{t.id}::PIN (#{typeid}) cannot be the same as #{ids[typeid]}::PIN" %}
          {% else %}
            {% ids[typeid] = t %}
          {% end %}
      when {{t}}::PIN then entries.push {{t.id}}.from_io(io, fm)
        {% end %}
      end
      {% end %}
    end

    new entries
  end
end

# `PIN` must be defined and it must be `Int32`
abstract class Raft::Log::Entry
  abstract def iobody(io : IO, fm : IO::ByteFormat)
  abstract def from_io(io : IO, fm : IO::ByteFormat)

  macro inherited
    def self.from_io(io : IO, fm : IO::ByteFormat)
      from_io(io, fm)
    end

    def to_io(io : IO, fm : IO::ByteFormat)
      {{ @type }}::PIN.to_io(io, fm)
      iobody(io, fm)
    end
  end
end
