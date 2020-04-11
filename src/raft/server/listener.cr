# Listens for incoming connections from peers and handles the
# complexities of establishing them as `Raft::Peer` objects
# before returning them to the `Raft::Server`
class Raft::Server::Listener
  # The transport object
  @server : TCPSocket|OpenSSL::SSL::Server
  @new_conns : Array(TCPSocket|OpenSSL::SSL::Server)

  def initialize(
      server : TCPSocket|OpenSSL::SSL::Server,
      context = OpenSSL::SSL::Context::Server
    )
    if context
      @server = OpenSSL::SSL::Server.new(server, context)
    else
      @server = server
    end
  end

  def listen
    spawn do
      loop do
        if client = @server.accept?

        else

        end
      end
    end
  end
end
