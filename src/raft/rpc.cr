module Raft::RPC
  abstract struct NetComm
    # Single byte control characters, written in binary notation
    # to ensure that there are no accidental duplicates
    #
    # Many are pulled from ASCII/Unicode
    #
    # They are represented here as UInt8, as it is easier to work
    # with given the surrounding context (mainly because unicode is not
    # guaranteed to be one or two bytes).

    # [Start of Text](https://codepoints.net/U+0002) - Used in `NetComm` at the end of the
    # header section to indicate the start of the data section
    STX = 0x02_u8

    # [End of Transmission](https://codepoints.net/U+0004) - Used in `NetComm` to signal the end of
    # the packet.
    EOT = 0x04_u8

    # [Acknowledge](https://codepoints.net/U+0006) is used in `NetComm` to denote boolean `true`
    ACK = 0x06_u8

    # [Not Acknowledged](https://codepoints.net/U+0015) - Used in `NetComm` to denote boolean `false`
    NAK = 0x15_u8

    # [Record Separator](https://codepoints.net/U+001E) - Used in `NetComm` to separate `NetComm::Entry`
    RS = 0x1E_u8

    alias Format = IO::ByteFormat::NetworkEndian
    abstract def to_io(io : IO, fm : IO::ByteFormat)
  end
end

require "./rpc/request-vote"
require "./rpc/append-entries"
