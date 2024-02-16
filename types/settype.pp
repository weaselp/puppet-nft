# Nftables named set types
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets
type Nft::Settype = Enum[
  'ipv4_addr',
  'ipv6_addr',
  'ether_addr',
  'inet_proto',
  'inet_service',
  'mark',
  'ifname',
]
