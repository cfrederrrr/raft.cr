module Raft::Version
  MAJOR = 0_u8
  MINOR = 1_u8
  PATCH = 0_u8

  def self.to_i
    1_000_000 * MAJOR +
    1_000 * MINOR +
    PATCH
  end

  def self.to_s(io : IO)
    io << MAJOR << '.'
    io << MINOR << '.'
    io << PATCH
  end

  # Used to indicate the version
  def self.to_io(io : IO, fm : IO::ByteFormat)
    MAJOR.to_io(io, fm)
    MINOR.to_io(io, fm)
    PATCH.to_io(io, fm)
  end
end
