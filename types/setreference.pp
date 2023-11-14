# Nftables reference to a set with @<name>
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets
type Nft::Setreference = Pattern[/\A@[a-z][a-z0-9_-]*\z/]
