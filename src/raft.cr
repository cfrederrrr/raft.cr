module Raft
  alias PacketFormat = IO::ByteFormat::NetworkEndian
  alias DiskFormat = IO::ByteFormat::SystemEndian
end

require "./raft/version"
require "./raft/rpc"
require "./raft/log"
require "./raft/server"
