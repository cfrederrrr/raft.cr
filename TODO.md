# Questions and TODOs
1. Move start_cluster and start_service into launch, as it is all one (mostly) linear sequence, and the helper methods are not used anywhere else
1. Sort out peer creation
1. Decide when/how to write to disk, paying special attention to how logs get written
  - should `Raft::Log::Entry` include an index?
  - should `Raft::Log::Entry@index` be treated as the `Raft::Log@commit_index` ?
1. Should there be a config option for much history to keep in memory?  
Maybe the leading server should only keep as many entries as are necessary to get the peer furthest behind up to speed
1. Compress `Raft::Log` written to disk? Should it be configurable?
1. Encrypt `Raft::Log` written to disk? Should that be configurable?
1. Need to start writing tests soon.
