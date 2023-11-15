# What defines an nftables string
# cf. https://www.netfilter.org/projects/nftables/manpage.html
# or https://www.mankier.com/8/nft#Data_Types
type Nft::String = Pattern[/\A[a-zA-Z_][a-zA-Z0-9\/_.-]*\z/]
