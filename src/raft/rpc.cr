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

    # [Start of Text](https://codepoints.net/U+0002)
    STX = 0x02_u8

    # [End of Text](https://codepoints.net/U+0003)
    ETX = 0x03_u8

    # [End of Transmission](https://codepoints.net/U+0004)
    EOT = 0x04_u8

    # [Acknowledge](https://codepoints.net/U+0001) is used in `NetComm` to denote boolean `true`
    ACK = 0x06_u8

    # Used in `NetComm` to denote boolean `false`
    NAK = 0x15_u8

    # Used in `NetComm` to separate `NetComm::Entry`
    RS = 0x1e_u8

    SSA = 0x86_u8
    ESA = 0x87_u8

    alias FM = IO::ByteFormat::NetworkEndian
    abstract def to_io(io : IO, fm : IO::ByteFormat)
    # abstract def initialize(io : IO, format : IO::ByteFormat)
  end
end

require "./rpc/request-vote"
require "./rpc/append-entries"
