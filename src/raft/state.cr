abstract class Raft::State(S)
  # # persistent state
  # getter current_term : Int32
  # getter voted_for : Int32
  # getter log : Array(S)
  #
  #
  # # volatile state (all)
  # getter commit_idx : Int32
  #
  # # volatile state (leader)
  # getter next_index : Array(Int32)
  # getter match_index : Array(Int32)
end
