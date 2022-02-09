# The nftables chain types
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Chains
type Nry_nft::ChainType = Enum['filter', 'nat', 'route']
