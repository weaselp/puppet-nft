# Nftables name of a named set
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets
type Nft::Setname = Pattern[/\A[a-z][a-z0-9_-]*\z/]
