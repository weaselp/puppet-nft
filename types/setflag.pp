# Nftables named set flags
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets
type Nft::Setflag = Enum[
  'constant',
  'interval',
  'timeout',
]
