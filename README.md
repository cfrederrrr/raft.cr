# raft

[Raft](https://raft.github.io/) implementation for Crystal-Lang

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     raft:
       github: your-github-user/raft
   ```

2. Run `shards install`

## Usage

```crystal
require "raft"
```

## About
This shard implements the specification laid out in the [raft paper](https://raft.github.io/raft.pdf) written by Diego Ongaro and John Ousterhout.

### Packets

#### Types
+ `+0xAE` Append Entries RPC
+ `-0xAE` Append Entries Result
+ `+0xF9` Request Vote
+ `-0xF9` Request Vote Result

#### Requests

##### RequestVote
Name | Size
-|-
Version | 24 Bits
Type Indicator | 16 Bits
Term | 32 Bits
Candidate ID | 32 Bits
Last log index | 32 Bits
Last log term | 32 Bits

##### AppendEntries
Name|Size
-|-
Version | 24 Bits
Type indicator | 16 Bits
Term | 32 Bits
Leader ID | 32 Bits
Leader Commit | 32 Bits
Previous Log Index | 32 Bits
Previous Log Term | 32 Bits
Size | 8 Bits
Entries | 0+ Bits

#### Results
##### RequestVote
Name|Size
-|-
Version | 24 Bits
Type Indicator | 32 Bits
Term | 32 Bits
Vote Granted | 8 Bits

##### AppendEnties
Name|Size
-|-
Version | 24 Bits
Type Indicator | 32 Bits
Term | 32 Bits
Success | 8 Bits


## Contributing

1. Fork it (<https://github.com/your-github-user/raft/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Carl Frederick](https://github.com/your-github-user) - creator and maintainer
