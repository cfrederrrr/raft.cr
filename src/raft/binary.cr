module Raft::Binary
  # Single byte control characters, written in binary notation
  # to ensure that there are no accidental duplicates
  #
  # Many are pulled from ASCII/Unicode
  #
  # They are represented here as UInt8, as it is easier to work
  # with given the surrounding context (mainly because unicode is not
  # guaranteed to be one or two bytes).

  # [Start of Text](https://codepoints.net/U+0002) - Used in `Packet` at the
  # end of the header section to indicate the start of the data section
  STX = 0x02_u8

  # [End of Transmission](https://codepoints.net/U+0004) - Used in `Packet` to
  # signal the end of the packet.
  EOT = 0x04_u8

  # [Acknowledge](https://codepoints.net/U+0006) - Denotes boolean `true`
  ACK = 0x06_u8

  # [Not Acknowledged](https://codepoints.net/U+0015) - Denotes boolean `false`
  NAK = 0x15_u8

  # [Record Separator](https://codepoints.net/U+001E) - Useful for indicating
  # the end of one record, and/or the beginning of another
  SEP = 0x1E_u8

  # Writes the type number to the `IO`. This should be a constant
  @[AlwaysInline]
  def tnum
    {{@type.constant(:TNUM)}}
  end

  # Writes any other identifying or preliminary information to the
  abstract def write_heading(io : IO, fm : IO::ByteFormat)

  # The actual contents of the
  abstract def write_body(io : IO, fm : IO::ByteFormat)

  # Any final information that doesn't belong in the body
  abstract def write_footing(io : IO, fm : IO::ByteFormat)

  # Writes the binary information to the `IO`.
  #
  # The writes occur in this order
  # - Heading - Custom identifying information, or flags
  # - Type Number - Indicates the type to the receiver of the `IO`
  # - Body - the basic contents of this object
  # - Footing - Informs the receiver of the `IO` that there is no more info
  def to_io(io : IO, fm : IO::ByteFormat)
    write_heading(io, fm)
    tnum.to_io(io, fm)
    write_body(io, fm)
    write_footing(io, fm)
    EOT.to_io(io, fm)
  end
end
