# Nftables.conf define when used (i.e. wit the $)
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets#nftables.conf_syntax
type Nft::Objectreference = Pattern[/\A\$[A-Z][A-Z0-9_]*\z/]
