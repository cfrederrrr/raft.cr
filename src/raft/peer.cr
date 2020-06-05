require "uri"
require "openssl"

class Raft::Peer
  alias Transport = TCPSocket|OpenSSL::SSL::Socket
  alias TLSContext = OpenSSL::SSL::Context::Client
  getter id : Int64

  # :nodoc:
  @socket : Transport

  # property timeout : Float32 = Time::Span.new(nanoseconds: 300_000_000)

  getter next_index : UInt64 = 0_u64
  getter match_index : UInt64 = 0_u64

  def initialize(@socket, @id, @next_index, @match_index)
  end

  def self.handshake(packet : RPC::Hello, addr : URI, ctx : TLSContext? = nil)
    socket = TCPSocket.new(uri.host, uri.port)
    socket = OpenSSL::SSL::Socket::Client.new(socket, ctx) if ctx
    # need to find out if there is data in the socket before proceeding
    # if there is data in the socket, do this part second
    # if there is no data in the socket
    #
    # on second thought - don't use `.handshake(RPC::Hello, Transport)`
    # when the connection is incoming.
    # instead, use `.new(Int64, Transport, UInt64, UInt64)` from the
    # Raft::Server context
    spawn do
      packet.to_io(socket, IO::ByteFormat::NetworkEndian)
      socket.flush
      result = Packet.from_io(socket, IO::ByteFormat::NetworkEndian)
      if result.is_a?(RPC::Hello)
        return new socket, result.id, result.next_index, result.match_index
      else
        raise "bad response from peer - handshake failed"
      end
    end
  end

  def handshake(packet : RPC::Hello socket : TCPSocket|OpenSSL::SSL::Socket?)
    @socket = socket if socket
    spawn do
      packet.to_io(@socket, IO::ByteFormat::NetworkEndian)
      socket.flush
      result = Packet.from_io(socket, IO::ByteFormat::NetworkEndian)

      # early return conditions mean the handshake fails and the peer is
      # no longer viable

      # this result doesn't work for this interaction
      return unless result.is_a?(RPC::Hello)

      # this peer may be outright untrustworthy if the term in the result is
      # lower than the term of this peer
      #
      # this condition might warrant an exception to abandon the cluster
      # altogether so as not to poison data, or reveal logs to imposters
      return if result.term < @term

      # this peer may be outright untrustworthy if the commit index in the
      # result is lower than the commit index of this peer
      #
      # this condition might warrant an exception to abandon the cluster
      # altogether so as not to poison data, or reveal logs to imposters
      return if result.commit_index < @match_index

      # DO NOT update the indexes of this peer - that will happen during the
      # `Raft::Server`'s main loop, if it is the leader, or 
      return self
    end
  end

  def send(packet : Packet)
    spawn do
      packet.to_io(@socket, IO::ByteFormat::NetworkEndian)
      socket.flush
    end
  end

  def read(timeout : Float32?)
    Packet.from_io(@socket, IO::ByteFormat::NetworkEndian)
  end
end
