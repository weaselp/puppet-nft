# Create a nftables chain in the nftables config file
#
# Chains come in two forms: base chains are chains that the kernel hooks into
# while processing a packet.  These chains may then also jump to non-base-chains.
# See the netfilter documentation for more details.
#
# @param chain       The name of the chain
# @param af          Address family (inet, ip, ip6, etc)
# @param table       The name of the table
# @param base_chain
#   Whether this is a base chain
#
#   If so, we add hooks and need to define hook, type, and priority.
# @param hook        If a base chain, the name of the hook
# @param type        If a base chain, the type of this chain (filter, nat, route)
# @param priority    If a base chain, the priority of this chain.
# @param rules_order If we pass a set of rules to this chain here, at what order number to add it to the concat.
# @param rules       A list of rules to pass here directly.  More can be added later using nry_nft::rule.
#
# Example:
#   nry_nft::chain{ 'input': }
#   nry_nft::chain{ 'forward': }
#   nry_nft::chain{ 'output': }
#
#   nry_nft::chain{ 'log_reject_drop':
#     rules => [
#       "limit rate 5/minute burst 5 packets log flags all counter",
#       "limit rate 60/minute burst 120 packets meta l4proto tcp counter reject with tcp reset",
#       "limit rate 60/minute burst 120 packets meta l4proto != tcp counter reject with icmpx type admin-prohibited",
#       'counter drop',
#     ]
#   }
define nry_nft::chain(
  Nry_nft::String $chain = $name,
  Nry_nft::AddressFamily $af = 'inet',
  Nry_nft::String $table = 'filter',
  Boolean $base_chain = $chain =~ Nry_nft::ChainHook,
  Optional[Nry_nft::ChainHook]     $hook     = if $base_chain { $chain } else { undef },
  Optional[Nry_nft::ChainType]     $type     = if $base_chain { $table } else { undef },
  Optional[Nry_nft::ChainPriority] $priority = if $base_chain {
    "${table}-${chain}" ? {
      'nat-prerouting'  => 'dstnat',
      'nat-postrouting' => 'srcnat',
      default           => 'filter' } } else { undef },
  Integer $rules_order = 0,
  Optional[Array[String]] $rules = undef,
) {
  if $base_chain {
    $content = "table ${af} ${table} { chain ${chain} { type ${type} hook ${hook} priority ${priority}; }; }"
  } else {
    $content = "table ${af} ${table} { chain ${chain} {  }; }"
  }

  ensure_resource('nry_nft::file', '010-chains', { })
  nry_nft::fragment { "chains/${af}/${table}/${chain}":
    target  => '010-chains',
    content => $content,
  }

  nry_nft::file { "050-rules/${af}/${table}/${chain}":
  }

  if $rules {
    nry_nft::rule{ "chain-${chain}-initrules":
      rule  => $rules.join(";\n  "),
      chain => $chain,
      order => $rules_order,
    }
  }
}
