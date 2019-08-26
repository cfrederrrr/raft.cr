struct Raft::Version
  include Comparable(Int32)
  def <=>(other : Int32)
    self.to_u <=> other
  end

  MAJOR = 0_u8
  MINOR = 1_u8
  PATCH = 0_u8

  # :nodoc:
  INTEGER = to_u

  # :nodoc:
  STRING = to_s

  # Used to indicate the version of an outgoing `Raft::RPC::Packet` and to determine the
  # safety of parsing and handling of an incoming `Raft::RPC::Packet`
  def self.to_io(io : IO, fm : IO::ByteFormat = IO::ByteFormat::NetworkEndian)
    MAJOR.to_io(io, fm)
    MINOR.to_io(io, fm)
    PATCH.to_io(io, fm)
  end

  # Major revision
  getter major : UInt8

  # Minor revision
  getter minor : UInt8

  # Patch revision
  getter patch : UInt8

  def initialize(@major = MAJOR, @minor = MINOR, @patch = PATCH)
  end

  # Checks whether this instance is the same as the current version
  def current?
    @major == MAJOR &&
    @minor == MINOR &&
    @patch == PATCH
  end

  # Returns `true` if this instance is less than `Raft::VERSION`
  def behind?
    to_u - INTEGER < 0
  end

  # Returns `true` if this instance is greater than `Raft::VERSION`
  def ahead?
    to_u - INTEGER > 0
  end

  # Checks whether the instance's `@major` is the same as `MAJOR`.
  # As a major revision necessarily constitutes breaking changes,
  # packets with a different `@major` revision will surely fail
  # and should be thrown away (or raised and logged).
  #
  # We don't check `@minor` or `@patch`, because we want it to be
  # possible to upgrade single `Raft::Server` instances without
  # bringing down the entire cluster.
  def safe?
    MAJOR == @major
  end

  # Converts the current version to an unsigned integer
  # to simplify comparison
  def self.to_u
    version = 0_u + MAJOR
    version <<= 8
    version += MINOR
    version <<= 8
    version + PATCH
  end

  # Converts the version of this instance to an unsigned integer
  # to simplify comparison
  def to_u
    version = 0_u + @major
    version <<= 8
    version += @minor
    version <<= 8
    version + @patch
  end

  # Returns the semantic-version string of the current version
  def self.to_s(io : IO)
    io << MAJOR << '.'
    io << MINOR << '.'
    io << PATCH
  end

  # Used to
  def to_s(io : IO)
    io << @major << '.'
    io << @minor << '.'
    io << @patch
  end
end

Raft::VERSION = Raft::Version.to_s
