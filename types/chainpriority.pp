# The priority strings that are accepted for base chains
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Chains
type Nry_nft::ChainPriority = Variant[Integer,Enum['raw', 'mangle', 'dstnat', 'filter', 'security', 'srcnat']]
