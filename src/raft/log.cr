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

  # Applies an entry to `@entries` and updates `@term` to match
  # that of the entry
  def append(entry : Entry)
    return false unless @term <= entry.term
    @entries.push entry
    @term = entry.term
  end

  def to_io(io : IO, fm : IO::ByteFormat)
    @entries.each do |entry|
      entry.to_io(io, fm)
    end
  end

  # it may make more sense to simply include Enumerable(Entry)
  # and delegate #each to @entries
  #
  # also, at some point, we will need to make log be able to dump
  # entries to disk or wherever and shrink the size of the array
  # to keep memory usage reasonable.  this will almost definitely mean
  # that `Entry` will have to include an index as well so that they can
  # be read (either back into the array, or not) from disk as well
  #
  # unfortunately, this means keeping two UInt64 with every entry... :(
  # maybe there is some magic to be done with smaller UInts on older entries
  # or perhaps some way of only writing the term if there is a change to the term
  #
  # there may also be a trick available if we write the term after the update
  # contents instead of before, but that could get difficult as users come up with
  # complex update objects since we also don't want to have to rewrite the entire
  # state machine for every log entry, which makes updates variable in length
  #
  # for a first-pass, this will have to suffice

  def select(min_term : UInt64)
    selection = [] of Entry
    index = -1
    entry = @entries[index]
    while min_term >= entry.term
      index -= 1
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
