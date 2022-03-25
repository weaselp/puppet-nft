# A simple rule from IP addresses to a TCP or UDP port
#
# @param saddr        A list of source addresses
# @param dport        A target port
# @param proto        Whether this is a TCP or UDP port
# @param chain        The name of the chain
# @param af           Address family (inet, ip, ip6, etc)
# @param table        The name of the table
# @param description  A description or comment for this rule to put into the nftables config
# @param order        Where to put this rule in the concat file
define nry_nft::simple(
  Variant[Stdlib::IP::Address, Array[Stdlib::IP::Address]] $saddr,
  Optional[Stdlib::Port]                                   $dport = undef,
  Enum['tcp', 'udp']                                       $proto = 'tcp',
  Nry_nft::String                                          $chain = 'input',
  Nry_nft::AddressFamily                                   $af = 'inet',
  Nry_nft::String                                          $table = 'filter',
  Optional[String]                                         $description = undef,
  Integer                                                  $order = 200,
) {
  $ip4 = $saddr.filter |$a| { $a !~ Stdlib::IP::Address::V6 }
  $ip6 = $saddr.filter |$a| { $a =~ Stdlib::IP::Address::V6 }

  if $dport {
    $dport_rule = "${proto} dport ${dport}"
  } else {
    $dport_rule = undef
  }
  $rule =
    unless empty($ip6) { [ "${dport_rule} ip6 saddr { ${ip6.join(', ')} } counter accept" ] }
    else { [] }
    +
    unless empty($ip4) { [ "${dport_rule} ip saddr { ${ip4.join(', ')} } counter accept" ] }
    else { {} }

  nry_nft::rule{ "nry_nft::simple:${name}":
    rule        => $rule,
    chain       => $chain,
    af          => $af,
    table       => $table,
    description => $description,
    order       => $order,
  }
}
