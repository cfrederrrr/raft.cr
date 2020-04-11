require "socket"

module Raft
  module RPC
  end
end

class Raft::RPC::RequestVote
  property term : Int32
  property candidate_id : Int32
  property last_log_index : Int32
  property last_log_term : Int32

  def self.new(io)
    from_io(io)
  end

  def self.from_io(io)
    term = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    candidate_id = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    last_log_index = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    last_log_term = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    new term, candidate_id, last_log_index, last_log_term
  end

  def initialize(@term, @candidate_id, @last_log_index, @last_log_term)
  end

  def to_s(io)
    io << @term << '\0'
    io << @candidate_id << '\0'
    io << @last_log_index << '\0'
    io << @last_log_term << '\0'
    io << '\0'
  end

  def to_io(io)
    @term.to_io(io, IO::ByteFormat::NetworkEndian)
    @candidate_id.to_io(io, IO::ByteFormat::NetworkEndian)
    @last_log_index.to_io(io, IO::ByteFormat::NetworkEndian)
    @last_log_term.to_io(io, IO::ByteFormat::NetworkEndian)
    io
  end
end

class Raft::RPC::RequestVote::Response
  property term : Int32
  property vote_granted : Bool

  def self.from_io(io)
    term = io.read_bytes(Int32, IO::ByteFormat::NetworkEndian)
    vote_granted = io.read_bytes(UInt8, IO::ByteFormat::NetworkEndian) != 0
    new term, vote_granted
  end

  def self.new(io)
    from_io(io)
  end

  def initialize(@term, @vote_granted)
  end

  def to_io(io)
    @term.to_io(io, IO::ByteFormat::NetworkEndian)
    (@vote_granted ? 1 : 0).to_io(io, IO::ByteFormat::NetworkEndian)
  end
end

server = TCPServer.new("localhost", 1234)

term = 0

loop do
  server.accept do |client|
    request = Raft::RPC::RequestVote.new(client)
    if request.term != term
      Raft::RPC::RequestVote::Response.new(request.term + 1, true).to_io(client)
      puts "true"
    else
      Raft::RPC::RequestVote::Response.new(request.term, false).to_io(client)
      puts "false"
    end
  end
end
