module Raft::State
  class Persistent
    getter current_term : UInt64
    getter voted_for : UInt64?
    getter log : Raft::Log

    def initialize(@current_term, @voted_for = nil, @log = Raft::Log(T)) forall T
    end

    def initialize(init_state : T) forall T
      @current_term = 0_u64
      @voted_for = nil
      @log = [init_state]
    end
  end

  # class Volatile
  #   getter commit_index : UInt32
  #   getter last_applied : UInt32
  # end
end

# class Raft::VolatileState # < Raft::State
#   @commit_idx = nil
# end
