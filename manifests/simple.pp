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
# @param saddr_not   A negative list of source addresses
# @param daddr_not   A negative list of destination addresses
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
# @param log_rule     Log rule to add before the final action
# @param action       What to do with matches (accept, drop, ..)
# @param snat         Address to source nat to (mutually exclusive with other action items)
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
# @example from networks
#    nft::simple{ 'allow-mta-submission':
#      saddr => $my_networks,
#      dport => 587,
#    }
# @example in a different chain
#    nft::simple{ "allow-extra-ssh":
#      chain => 'ssh-filter',
#      saddr => $src_address,
#    }
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
  Optional[Variant[ Stdlib::IP::Address, Nft::Objectreference, Nft::Setreference,
                    Array[Variant[Stdlib::IP::Address, Nft::Objectreference]]]] $saddr_not = undef,
  Optional[Variant[ Stdlib::IP::Address, Nft::Objectreference, Nft::Setreference,
                    Array[Variant[Stdlib::IP::Address, Nft::Objectreference]]]] $daddr_not = undef,
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
  Optional[Pattern[/\Alog.*\z/]]  $log_rule = undef,
  Optional[String]                $action = undef,
  Optional[Variant[Stdlib::IP::Address, Nft::Objectreference]] $snat = undef,
) {
  if [$action, $snat].map |$x| { Integer($x !~ Undef) }.reduce |$memo, $value| { $memo + $value } > 1 {
    fail("${name}: Cannot have more than one action option (action, snat)")
  }

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
    $comment_info = "${_description} (${name})"
  } else {
    $comment_info = $name.regsubst(/"/, '', 'G')
  }
  if $comment_info.length > 127 {
    $commentstring = "comment \"${comment_info[0, 124]}..\""
  } else {
    $commentstring = "comment \"${comment_info}\""
  }

  # Make the nftables rule require all the referenced sets
  $require_sets = (
    Array(pick($saddr, []), true) +
    Array(pick($daddr, []), true) +
    Array(pick($saddr_not, []), true) +
    Array(pick($daddr_not, []), true)
  ).map |$a| {
    if $a =~ Nft::Setreference {
      $set_name = $a.regsubst(/^@/, '')
      unless Nft::Set[ $set_name ]['type'] in ['ipv4_addr', 'ipv6_addr'] {
        fail("Named set ${set_name} is not an address type but ${Nft::Set[ $set_name ]['type']}.")
      }
      Nft::Set[ $set_name ]
    }
  }.delete_undef_values()


  [ $addr_4_rules, $addr_6_rules ] =
  [
    [ $saddr    , 'saddr' ],
    [ $saddr_not, 'saddr != ' ],
    [ $daddr    , 'daddr' ],
    [ $daddr_not, 'daddr != ' ],
  ].reduce([[], []]) |$rule46_tuple, $this_instance| {
    [$addresses, $rule_string] = $this_instance
    $addresses_4 = nft::af_filter_address_set_object($addresses, 'v4')
    $addresses_6 = nft::af_filter_address_set_object($addresses, 'v6')

    # lint:ignore:140chars
    $rule_4 = $addresses_4.length() ? { 0 => undef, 1 => "ip  ${rule_string} ${addresses_4[0]}", default => "ip  ${rule_string} { ${addresses_4.join(', ')} }", }
    $rule_6 = $addresses_6.length() ? { 0 => undef, 1 => "ip6 ${rule_string} ${addresses_6[0]}", default => "ip6 ${rule_string} { ${addresses_6.join(', ')} }", }
    # lint:endignore

    [ $rule46_tuple[0] + [$rule_4], $rule46_tuple[1] + [$rule_6] ]
  }.map |$filter_list| { $filter_list.delete_undef_values() }

  if $snat {
    $snat4 = nft::af_filter_address_set_object($snat, 'v4')
    $snat6 = nft::af_filter_address_set_object($snat, 'v6')
    if !$addr_4_rules.empty() and $snat4.empty() {
      fail("Have v4 rules but snat target no v4 addresses (v4 rules: ${addr_4_rules}")
    }
    if !$addr_6_rules.empty() and $snat6.empty() {
      fail("Have v6 rules but snat target no v6 addresses (v6 rules: ${addr_6_rules}")
    }
    unless $snat4.empty() or $snat4.length() == 1 {
      fail("Unexpected length of snat4 target ${snat4}")
    }
    unless $snat6.empty() or $snat6.length() == 1 {
      fail("Unexpected length of snat6 target ${snat6}")
    }

    $_action4 = unless $snat4.empty() { "snat to ${snat4[0]}" }
    $_action6 = unless $snat6.empty() { "snat to ${snat6[0]}" }
    $_action = false
  } else {
    $_action4 = undef
    $_action6 = undef
    $_action = pick($action, 'accept')
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

  $do_v4 = !$addr_4_rules.empty() or $_action4
  $do_v6 = !$addr_6_rules.empty() or $_action6

  # lint:ignore:140chars
  $_rule =
    if $do_v4 { [ ($if_rules + $proto_rules + $port_rules + $addr_4_rules + [$counterstring, $log_rule, pick($_action4, $_action), $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }
    +
    if $do_v6 { [ ($if_rules + $proto_rules + $port_rules + $addr_6_rules + [$counterstring, $log_rule, pick($_action6, $_action), $commentstring]).delete_undef_values().join(' ') ] }
    else { [] }

  $rule =
    if $_rule.empty() { [ ($if_rules + $proto_rules + $port_rules + [$counterstring, $log_rule, $_action, $commentstring]).delete_undef_values().join(' ') ] }
    else { $_rule }
  # lint:endignore

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
