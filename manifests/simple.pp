# A simple rule from IP addresses to a TCP or UDP port
#
# @param saddr
#   A list of source addresses.
#   If not provided, allow from everywhere, but see the explanation at daddr.
# @param daddr
#   A list of destination addresses.
#   If not provided, allow to everywhere.
#
#   Note that the interaction with different address families is tricky.
#   - If saddr and daddr are empty, then IPv4 and IPv6 are allowed.
#   - If saddr and/or daddr only have addresses of one address family, then
#     only that address family is allowed.
#   - If the union of saddr and daddr have both IPv4 and IPv6, then both
#     are processed, with saddr and daddr filtering based on the given lists,
#     with an empty list (after AF filtering) meaning everything is allowed.
# @param dport
#   A target port, list of target ports, or a range (as string) from-to target port.
#   If not provided, do not match on ports
# @param sport
#   A sourceport port, list of target ports, or a range (as string) from-to source port.
# @param proto        Whether this is a TCP or UDP port
# @param chain        The name of the chain
# @param af           Address family (inet, ip, ip6, etc)
# @param table        The name of the table
# @param description  A description or comment for this rule to put into the nftables config
# @param iif          A list of in-interfaces to match;  if not provided, do not match on interfaces.
# @param oif          A list of out-interfaces to match;  if not provided, do not match on interfaces.
# @param iifname      A list of in-interface-namess to match;  if not provided, do not match on interface names.
# @param oifname      A list of out-interface-names to match;  if not provided, do not match on interface names.
# @param order        Where to put this rule in the concat file
# @param counter      Whether to add a counter to this rule
# @param action       What to do with matches (accept, drop, ..)
define nft::simple(
  Optional[Variant[Stdlib::IP::Address, Array[Stdlib::IP::Address]]] $saddr = undef,
  Optional[Variant[Stdlib::IP::Address, Array[Stdlib::IP::Address]]] $daddr = undef,
  Optional[Variant[Stdlib::Port,Array[Variant[Stdlib::Port,Pattern[/\A[0-9]+-[0-9]+\z/]],1],Pattern[/\A[0-9]+-[0-9]+\z/]]] $dport = undef,
  Optional[Variant[Stdlib::Port,Array[Variant[Stdlib::Port,Pattern[/\A[0-9]+-[0-9]+\z/]],1],Pattern[/\A[0-9]+-[0-9]+\z/]]] $sport = undef,
  Optional[Variant[String,Array[String, 1]]] $iif = undef,
  Optional[Variant[String,Array[String, 1]]] $oif = undef,
  Optional[Variant[String,Array[String, 1]]] $iifname = undef,
  Optional[Variant[String,Array[String, 1]]] $oifname = undef,
  Enum['tcp', 'udp']      $proto = 'tcp',
  Nft::String         $chain = 'input',
  Nft::AddressFamily  $af = 'inet',
  Nft::String         $table = 'filter',
  Optional[String]        $description = undef,
  Optional[Integer]       $order = undef,
  Boolean                 $counter = true,
  String                  $action = 'accept',
) {
  $port_rules =
    [ ['dport', $dport],
      ['sport', $sport],
    ].map |$tuple| {
      [$port_type, $port_spec] = $tuple
      if $port_spec =~ Undef {
        undef
      } elsif $port_spec =~ Stdlib::Port {
        "${proto} ${port_type} ${port_spec}"
      } elsif $port_spec =~ String {
        "${proto} ${port_type} ${port_spec}"
      } else {
        "${proto} ${port_type} { ${port_spec.join(', ')} }"
      }
    }

  $counterstring = [undef, 'counter'][Integer($counter)]
  $commentstring = "comment \"${name}\""

  $sip4 = Array(pick($saddr, []), true).filter |$a| { $a !~ Stdlib::IP::Address::V6 }
  $sip6 = Array(pick($saddr, []), true).filter |$a| { $a =~ Stdlib::IP::Address::V6 }
  $ip6_saddr = $sip6.length() ? {
    0       => undef,
    1       => "ip6 saddr ${sip6[0]}",
    default => "ip6 saddr { ${sip6.join(', ')} }",
  }
  $ip4_saddr = $sip4.length() ? {
    0       => undef,
    1       => "ip saddr ${sip4[0]}",
    default => "ip saddr { ${sip4.join(', ')} }",
  }

  $dip4 = Array(pick($daddr, []), true).filter |$a| { $a !~ Stdlib::IP::Address::V6 }
  $dip6 = Array(pick($daddr, []), true).filter |$a| { $a =~ Stdlib::IP::Address::V6 }
  $ip6_daddr = $dip6.length() ? {
    0       => undef,
    1       => "ip6 daddr ${dip6[0]}",
    default => "ip6 daddr { ${dip6.join(', ')} }",
  }
  $ip4_daddr = $dip4.length() ? {
    0       => undef,
    1       => "ip daddr ${dip4[0]}",
    default => "ip daddr { ${dip4.join(', ')} }",
  }

  $if_rules =
    [ ['iif', $iif],
      ['oif', $oif],
      ['iifname', $iifname],
      ['oifname', $oifname],
    ].map |$tuple| {
      [$if_type, $if_spec] = $tuple
      if $if_spec =~ Undef {
        undef
      } elsif $if_spec =~ String {
        "${if_type} ${if_spec}"
      } elsif $if_spec =~ Array and $if_spec.size == 1 {
        "${if_type} ${if_spec[0]}"
      } elsif $if_spec =~ Array {
        "${if_type} {  ${iif.join(', ')} }"
      } else {
        fail("Unexpected type for ${if_type}; value is '${if_spec}'.")
      }
    }

  $_rule =
    if ($ip6_saddr or $ip6_daddr) { [ ($if_rules + $port_rules + [$ip6_saddr, $ip6_daddr, $counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }
    +
    if ($ip4_saddr or $ip4_daddr) { [ ($if_rules + $port_rules + [$ip4_saddr, $ip4_daddr, $counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }

  $rule =
    if $_rule.empty() { [ ($if_rules + $port_rules + [$counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { $_rule }

  nft::rule{ "nft::simple:${name}":
    rule        => $rule,
    chain       => $chain,
    af          => $af,
    table       => $table,
    description => $description,
    order       => $order,
  }
}
