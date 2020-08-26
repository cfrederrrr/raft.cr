require "uri"
require "openssl"

private alias TLS = OpenSSL::SSL

class Raft::Peer
  alias Transport = TCPSocket|TLS::Socket
  alias TLSContext = TLS::Context::Client

  getter id : Int64

  @socket : Transport
  @buffer : Channel(Packet?)

  getter next_index : UInt64 = 0_u64
  getter match_index : UInt64 = 0_u64

  def initialize(@socket, @id, @next_index, @match_index)
    @buffer = Channel(Packet?).new
  end

  def self.handshake(packet : RPC::Hello, config : Config::Peer)
    socket = TCPSocket.new(config.uri.host, config.uri.port)

    if config.heartbeat
      socket.read_timeout = config.heartbeat
      socket.write_timeout = config.heartbeat
    end

    if config.tls
      socket = OpenSSL::SSL::Socket::Client.new(socket, config.tls.context)
    end

    spawn do
      packet.to_io(socket, IO::ByteFormat::NetworkEndian)
      socket.flush
      result = Packet.from_io(socket, IO::ByteFormat::NetworkEndian)
    end

    if result.is_a?(RPC::Hello)
      return new socket, result.id, result.next_index, result.match_index
    else
      raise "bad response from peer - handshake failed"
    end
  end

  # Defines a way to refresh the underlying socket without removing the peer
  # from the `Raft::Server`'s peers. This can mitigate network interruptions
  # without
  def handshake(packet : RPC::Hello socket : TCPSocket|OpenSSL::SSL::Socket?)
    @socket = socket if socket

    spawn do
      packet.to_io(@socket, IO::ByteFormat::NetworkEndian)
      socket.flush
      result = Packet.from_io(socket, IO::ByteFormat::NetworkEndian)

      # early return conditions mean the handshake fails and the peer is
      # no longer viable. we close the connection in those cases, preferably
      # indicating to the peer that it should remove us from its
      # `@peers` list, if it is even still online

      # this result doesn't work for this interaction
      if ! result.is_a?(RPC::Hello)
        @socket.close
        return
      end

      # this peer may be outright untrustworthy if the term in the result is
      # lower than the term of this peer
      #
      # this condition might warrant an exception to abandon the cluster
      # altogether so as not to poison data, or reveal logs to imposters
      if result.term < @term
        @socket.close
        return
      end

      # this peer may be outright untrustworthy if the commit index in the
      # result is lower than the commit index of this peer
      #
      # this condition might warrant an exception to abandon the cluster
      # altogether so as not to poison data, or reveal logs to imposters
      if result.commit_index < @match_index
        @socket.close
        return
      end

      # DO NOT update the indexes of this peer - that will happen during the
      # `Raft::Server`'s main loop, if it is the leader, or
      return self
    end
  end

  # Sends a `Raft::Packet` through the `@socket`
  def send(packet : Packet)
    spawn do
      packet.to_io(@socket, IO::ByteFormat::NetworkEndian)
      socket.flush
    end
  end

  # Receives a `Raft::Packet` through the `@socket`
  def read(timeout : Float32?) : Packet?
    begin
      Packet.from_io(@socket, IO::ByteFormat::NetworkEndian)
      # https://github.com/crystal-lang/crystal/blob/5999ae29b/src/io/evented.cr#L124
    rescue IO::TimeoutError
      return nil
    end
  end
end
