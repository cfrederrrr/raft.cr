class Raft::Peer
  alias Transport = TCPSocket|OpenSSL::SSL::Socket
  getter id : Int64

  # :nodoc:
  @socket : Transport

  getter unread : Array(Packet)

  # property timeout : Float32 = Time::Span.new(nanoseconds: 300_000_000)

  getter next_index : UInt64 = 0_u64
  getter match_index : UInt64 = 0_u64

  def self.handshake(packet : RPC::Hello, socket : Transport)
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
      result = Packet.new(socket, IO::ByteFormat::NetworkEndian)
      if result.is_a?(RPC::Hello)
        return new socket, result.id, result.next_index, result.match_index
      else
        raise "bad response from peer - handshake failed"
      end
    end
  end

  def initialize(@socket, @id, @next_index, @match_index)
    @unread = [] of Packet
  end

  def send(packet : Packet)
    spawn do
      packet.to_io(@socket, IO::ByteFormat::NetworkEndian)
      socket.flush
    end
  end

  def read(timeout : Float32?)
    Packet.new(@socket, IO::ByteFormat::NetworkEndian)
  end
end
