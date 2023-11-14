# Nftables.conf define, during definition (i.e. without the $)
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets#nftables.conf_syntax
type Nft::Objectdefine = Pattern[/\A[A-Z][A-Z0-9_]*\z/]
