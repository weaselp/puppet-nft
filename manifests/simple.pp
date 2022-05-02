# A simple rule from IP addresses to a TCP or UDP port
#
# @param saddr
#   A list of source addresses.
#   If not provided, allow from everywhere.
# @param dport
#   A target port or list of target ports.
#   If not provided, allow all ports.
# @param proto        Whether this is a TCP or UDP port
# @param chain        The name of the chain
# @param af           Address family (inet, ip, ip6, etc)
# @param table        The name of the table
# @param description  A description or comment for this rule to put into the nftables config
# @param order        Where to put this rule in the concat file
# @param counter      Whether to add a counter to this rule
# @param action       What to do with matches (accept, drop, ..)
define nft::simple(
  Optional[Variant[Stdlib::IP::Address, Array[Stdlib::IP::Address]]] $saddr = undef,
  Optional[Variant[Stdlib::Port,Array[Stdlib::Port,1]]]  $dport = undef,
  Enum['tcp', 'udp']      $proto = 'tcp',
  Nft::String         $chain = 'input',
  Nft::AddressFamily  $af = 'inet',
  Nft::String         $table = 'filter',
  Optional[String]        $description = undef,
  Integer                 $order = 200,
  Boolean                 $counter = true,
  String                  $action = 'accept',
) {
  $ip4 = Array(pick($saddr, []), true).filter |$a| { $a !~ Stdlib::IP::Address::V6 }
  $ip6 = Array(pick($saddr, []), true).filter |$a| { $a =~ Stdlib::IP::Address::V6 }

  if $dport =~ Undef {
    $dport_rule = undef
  } elsif $dport =~ Stdlib::Port {
    $dport_rule = "${proto} dport ${dport}"
  } else {
    $dport_rule = "${proto} dport { ${dport.join(', ')} }"
  }
  $counterstring = [undef, 'counter'][Integer($counter)]
  $commentstring = "comment \"${name}\""

  $ip6_saddr = $ip6.length() ? {
    0       => undef,
    1       => "ip6 saddr ${ip6[0]}",
    default => "ip6 saddr { ${ip6.join(', ')} }",
  }
  $ip4_saddr = $ip4.length() ? {
    0       => undef,
    1       => "ip saddr ${ip4[0]}",
    default => "ip saddr { ${ip4.join(', ')} }",
  }

  $rule =
    if ($ip6_saddr) { [ [$dport_rule, $ip6_saddr, $counterstring, $action, $commentstring].delete_undef_values().join(' ') ] }
    else { [] }
    +
    if ($ip4_saddr) { [ [$dport_rule, $ip4_saddr, $counterstring, $action, $commentstring].delete_undef_values().join(' ') ] }
    else { [] }
    +
    if ($saddr =~ Undef) { [ [$dport_rule, $counterstring, $action, $commentstring].delete_undef_values().join(' ') ] }
    else { [] }

  nft::rule{ "nft::simple:${name}":
    rule        => $rule,
    chain       => $chain,
    af          => $af,
    table       => $table,
    description => $description,
    order       => $order,
  }
}
