# An nftables address family
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Address_Families
type Nft::AddressFamily = Enum['inet', 'ip', 'ip6', 'arp', 'bridge', 'netdev']
