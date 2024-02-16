# Nftables.conf define when used (i.e. wit the $)
# cf. https://wiki.nftables.org/wiki-nftables/index.php/Sets#nftables.conf_syntax
#
# Including internal objects
type Nft::Objectreference_internal = Pattern[/\A\$__[46]_[A-Z][A-Z0-9_]*\z/]
