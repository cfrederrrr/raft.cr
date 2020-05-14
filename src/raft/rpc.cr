# Namespace for RPC Packets
module Raft::RPC
end

require "./rpc/request-vote"
require "./rpc/append-entries"
require "./rpc/handshake"
