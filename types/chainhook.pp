# The list of chain hooks in nftables
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Address_Families
type Nft::ChainHook = Enum['ingress', 'prerouting', 'input', 'forward', 'output', 'postrouting']
