class Raft::Consensus
  property commit_index : UInt64 = 0
  property last_applied : UInt64 = 0
end
