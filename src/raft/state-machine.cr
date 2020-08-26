# The state machine managed by raft.
abstract class Raft::StateMachine
  # Must define a way of reading state values so that service
  # clients can obtain data.
  #
  # Any `Raft::Server` in the cluster can serve this data
  abstract def retrieve(key : String)

  # def retrieve(key : String)
  #   {% begin %}
  #   case key
  #   {% for ivar in @type.instance_vars %}
  #   when {{ivar.stringify}} then return @{{ivar.id}}
  #   {% end %}
  #   else raise "key #{key} not a member"
  #   end
  # end

  # Provide a way for `Raft::Server` to update the state machine.
  # This method will be used in two situations
  # 1. The server receives instructions from a service client to update state
  # 1. The leader of the cluster sends consensus updates via
  #    `Raft::RPC::AppendEntries`
  abstract def update(entry : Update)
end

# `TNUM` must be defined and it must be `Int32`
abstract class Raft::StateMachine::Update

  abstract def iobody(io : IO, fm : IO::ByteFormat)
  abstract def from_io(io : IO, fm : IO::ByteFormat)

  macro inherited
    @[AlwaysInline]
    def tnum
      {{@type}}::TNUM
    end

    def self.from_io(io : IO, fm : IO::ByteFormat)
      from_io(io, fm)
    end

    def to_io(io : IO, fm : IO::ByteFormat)
      {{@type}}::TNUM.to_io(io, fm)
      iobody(io, fm)
    end
  end
end
