# An nftables address family
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Address_Families
type Nry_nft::AddressFamily = Enum['inet', 'ip', 'ip6', 'arp', 'bridge', 'netdev']
