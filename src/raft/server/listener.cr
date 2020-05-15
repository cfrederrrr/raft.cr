require "socket"
require "openssl"

# Listens for incoming connections from peers and handles the
# complexities of establishing them as `Raft::Peer` objects
# before returning them to the `Raft::Server`
class Raft::Server::Listener
  alias Transport = TCPServer|OpenSSL::SSL::Socket::Server
  # The transport object
  @server : Transport
  @context : OpenSSL::SSL::Context::Server?
  @queue : Array(Packet) = [] of Packet

  def initialize(addr : URI, @context : OpenSSL::SSL::Context::Server? = nil)
    @server = TCPServer.new(addr.host, addr.port)
    @server = OpenSSL::SSL::Socket::Server.new(socket, context) if context
  end

  def listen
  end

  def stop
  end
end
