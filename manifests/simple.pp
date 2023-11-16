# A simple rule from IP addresses to a TCP or UDP port
#
# This is meant to abstract the most common instances of nftables rules.
# It will never be a way to do them all, nor is that the intention.
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
#   A target port (port number or service name from /etc/services),
#   A range of ports ("<number>-<number>" as string),
#   or a list of these.
#   If not provided, do not match on ports
# @param sport
#   Source ports in the same way as dport.
# @param proto
#   Whether this is TCP or UDP or something else (given protocol number).
#   Providing sport and dport may or may not make sense for a given protocol.
#   Defaults to 'tcp' if ports are given, none otherwise.
#   Using a set (i.e. list of ['tcp', 'udp']) is also possible.
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
#
# @example
#   nft::simple { 'allow-web':
#     dport   => [80, 443],
#   }
# @example
#   nft::simple { 'allow-ssh':
#     dport   => 22,
#     iifname => 'mgmt',
#   }
# @example allow-ssh
#   nft::simple { 'allow-ssh':
#     iifname => 'mgmt',
#     dport   => 22,
#     saddr   => ['10.0.0.0/8', '172.16.0.0/12'],
#   }
# @example allow-dns
#   nft::simple { 'allow-dns':
#     dport   => 'domain',
#     proto   => ['tcp', 'udp'],
#   }
# @example
#   nft::simple { 'from-guest-wifi':
#     iifname => 'wlan0',
#     action  => 'jump from-guests',
#   }
# @example # do not track the incoming traffic
#   nft::simple { "prerouting-notrack-${title}-${proto}":
#     chain   => 'prerouting',
#     iifname => $interface,
#     proto   => $proto,
#     dport   => $incoming_dport,
#     sport   => $incoming_sport,
#     action  => 'notrack',
#   }
# @example nat
#   nft::chain { 'prerouting':
#     table => 'nat',
#   }
#   nft::simple { 'redirect-incoming-gerrit-ssh':
#     chain  => 'prerouting',
#     table  => 'nat',
#     daddr  => $gerrit_service_ip,
#     dport  => 22,
#     action => "redirect to :${gerrit_ssh_port}",
#   }
define nft::simple(
  Optional[Variant[ Stdlib::IP::Address, Nft::Objectreference, Nft::Setreference,
                    Array[Variant[Stdlib::IP::Address, Nft::Objectreference]]]] $saddr = undef,
  Optional[Variant[ Stdlib::IP::Address, Nft::Objectreference, Nft::Setreference,
                    Array[Variant[Stdlib::IP::Address, Nft::Objectreference]]]] $daddr = undef,
  Optional[Variant[Nft::Port, Nft::Portrange, Array[Variant[Nft::Port, Nft::Portrange], 1]]] $dport = undef,
  Optional[Variant[Nft::Port, Nft::Portrange, Array[Variant[Nft::Port, Nft::Portrange], 1]]] $sport = undef,
  Optional[Variant[String,Array[String, 1]]] $iif = undef,
  Optional[Variant[String,Array[String, 1]]] $oif = undef,
  Optional[Variant[String,Array[String, 1]]] $iifname = undef,
  Optional[Variant[String,Array[String, 1]]] $oifname = undef,
  Optional[Variant[Enum['tcp', 'udp'], Integer, Array[Enum['tcp', 'udp']]]]
    $proto = if ($sport !~ Undef or $dport !~ Undef) { 'tcp' } else { undef },
  Nft::String         $chain = 'input',
  Nft::AddressFamily  $af = 'inet',
  Nft::String         $table = 'filter',
  Optional[String]        $description = undef,
  Optional[Integer]       $order = undef,
  Boolean                 $counter = true,
  String                  $action = 'accept',
) {
  if $proto =~ Undef {
    $proto_rules = undef
  } elsif $proto =~ Array {
    $proto_rules = ["meta l4proto { ${proto.join(', ')} }"]
  } else {
    $proto_rules = ["meta l4proto ${proto}"]
  }

  $port_rules =
    [ ['dport', $dport],
      ['sport', $sport],
    ].map |$tuple| {
      [$port_type, $port_spec] = $tuple
      $_proto = if $proto =~ Array { 'th' } else { $proto }
      if $port_spec =~ Undef {
        undef
      } elsif $port_spec =~ Array {
        "${_proto} ${port_type} { ${port_spec.join(', ')} }"
      } else {
        "${_proto} ${port_type} ${port_spec}"
      }
    }

  $counterstring = [undef, 'counter'][Integer($counter)]
  if $description {
    $_description = $description.regsubst(/"/, '', 'G')
    $commentstring = "comment \"${_description} (${name})\""
  } else {
    $commentstring = "comment \"${name}\""
  }

  # Make the nftables rule require all the referenced sets
  $require_sets = (Array(pick($saddr, []), true) + Array(pick($daddr, []), true)).map |$a| {
    if $a =~ Nft::Setreference {
      $set_name = $a.regsubst(/^@/, '')
      unless Nft::Set[ $set_name ]['type'] in ['ipv4_addr', 'ipv6_addr'] {
        fail("Named set ${set_name} is not an address type but ${Nft::Set[ $set_name ]['type']}.")
      }
      Nft::Set[ $set_name ]
    }
  }.delete_undef_values()

  $sip4 = nft::af_filter_address_set_object($saddr, 'v4')
  $sip6 = nft::af_filter_address_set_object($saddr, 'v6')
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

  $dip4 = nft::af_filter_address_set_object($daddr, 'v4')
  $dip6 = nft::af_filter_address_set_object($daddr, 'v6')
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
        "${if_type} {  ${if_spec.join(', ')} }"
      } else {
        fail("Unexpected type for ${if_type}; value is '${if_spec}'.")
      }
    }

  $_rule =
    if ($ip6_saddr or $ip6_daddr) { [ ($if_rules + $proto_rules + $port_rules + [$ip6_saddr, $ip6_daddr, $counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }
    +
    if ($ip4_saddr or $ip4_daddr) { [ ($if_rules + $proto_rules + $port_rules + [$ip4_saddr, $ip4_daddr, $counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }

  $rule =
    if $_rule.empty() { [ ($if_rules + $proto_rules + $port_rules + [$counterstring, $action, $commentstring]).delete_undef_values().join(' ') ] }
    else { $_rule }

  nft::rule{ "nft::simple:${name}":
    rule        => $rule,
    chain       => $chain,
    af          => $af,
    table       => $table,
    description => $description,
    order       => $order,
    require     => $require_sets,
  }
}
