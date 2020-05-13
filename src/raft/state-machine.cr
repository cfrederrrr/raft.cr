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
  abstract def update(entry : Log::Entry)
end
