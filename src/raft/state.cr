module Raft::State
  @current_term
  @voted_for = Int64? = nil
  @log : Raft::Log = Raft::Log.new
  @commit_index : Int32
  @last_applied : Int32
end
