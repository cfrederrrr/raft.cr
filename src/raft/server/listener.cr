require "socket"
require "openssl"

# Listens for and keeps track of incoming connections from peers and/or service
# clients
#
# It makes sockets available to `Raft::Server` for serving requests or
# participating in the cluster
class Raft::Server::Listener
  alias Transport = TCPSocket|OpenSSL::SSL::Socket::Server

  @server : TCPServer|OpenSSL::SSL::Server
  # @context : OpenSSL::SSL::Context::Server?
  @connections : Array(Transport)

  # Any object looking to access the connections list will see only open
  # connections, as closed ones are not useful.
  def connections
    @connections = @connections.reject &.closed?
  end

  def self.new(addr : URI, context : OpenSSL::SSL::Context::Server? = nil)
    server = TCPServer.new(addr.host, addr.port)
    server = OpenSSL::SSL::Server.new(server, context) if context
    new server
  end

  def initialize(@server)
    @connections = [] of Transport
  end

  def listen : Bool
    while listening?
      socket = @server.accept?
      if socket
        connections.push(socket) if socket
      end
    end
  end

  def listening?
    @listening
  end

  def stop
    @listening = false
  end
end
