module Raft::State
  class Persistent
    @current_term : UInt64
    @voted_for : UInt64?
    @log : Raft::Log

    def initialize(@current_term, @voted_for = nil, @log = Raft::Log(T)) forall T
    end

    def initialize(init_state : T) forall T
      @current_term = 0_u64
      @voted_for = nil
      @log = [] of T
    end
  end

  class Volatile
  end

  class Leader
  end
end

class Raft::VolatileState < Raft::State
  @commit_idx =
end
