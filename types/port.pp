# Nftables.conf port, either a number of a string from /etc/services
type Nft::Port = Variant[Stdlib::Port, Pattern[/\A[a-z][a-z0-9-]*\z/]]
