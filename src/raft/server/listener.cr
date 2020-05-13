require "socket"
require "openssl"

# Listens for incoming connections from peers and handles the
# complexities of establishing them as `Raft::Peer` objects
# before returning them to the `Raft::Server`
class Raft::Server::Listener

  # The transport object
  @server : TCPServer|OpenSSL::SSL::Socket::Server
  @context : OpenSSL::SSL::Context::Server
  @queue : Array(RPC::Packet) = [] of RPC::Packet

  def initialize(addr : URI, @context : OpenSSL::SSL::Context::Server?)
    socket = TCPSocket.new(addr.host, addr.port)
    if context
      @server = OpenSSL::SSL::Socket::Server.new(server, context)
    else
      @server = socket
    end
  end

  def listen

  end
end
