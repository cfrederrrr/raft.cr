# raft

TODO: Write a description here

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

TODO: Write usage instructions here

## About
This shard implements the specification laid out in the [raft paper](https://raft.github.io/raft.pdf) written by Diego Ongaro and John Ousterhout.

It uses

### Packets

#### Types
+ `0xAE00` Append Entries RPC
+ `0xAEF0` Append Entries Result
+ `0xF900` Request Vote
+ `0xF9F0` Request Vote Result

#### Requests

##### RequestVote
Name | Size (160 Bits total)
-|-
Type Indicator | 32 Bits
Candidate ID | 32 Bits
Last log index | 32 Bits
Last log term | 32 Bits

##### AppendEntries
Name|Size (224 Bits total)
-|-
Type indication | 32 Bits
Log Type Indicator | 32 Bits
Term | 32 Bits
Leader ID | 32 Bits
Leader Commit | 32 Bits
Previous Log Term | 32 Bits
Previous Log Index | 32 Bits
Entries | 2+ Bits

#### Results
##### RequestVote
Name|Size
-|-
Type Indicator|32 Bits
Term | 32 Bits
Vote Granted | 32 Bits

##### AppendEnties
Name|Size
-|-
Type Indicator|32 Bits
Term|32 Bits
Success|32 Bits


## Contributing

1. Fork it (<https://github.com/your-github-user/raft/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Carl Frederick](https://github.com/your-github-user) - creator and maintainer
