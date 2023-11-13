# Create an nftables named set in the nftables config file
#
# @param set         The name of the set
# @param af          Address family (inet, ip, ip6, etc)
# @param table       The name of the table
# @param type        The type of the objects in this set (cf Nft::Settype)
# @param flags       A list of flags for this set (cf Nft::Setflags)
#
# Example:
#   nft::set{ 'authnft-pape':
#     type  => 'ipv4_addr',
#     flags => [ 'timeout' ],
#   }
define nft::set(
  Nft::Settype $type,
  Nft::String $setname = $name,
  Nft::AddressFamily $af = 'inet',
  Nft::String $table = 'filter',
  Array[Nft::Setflag] $flags = [],
) {
  if $flags.empty {
    $_flags = undef
  } else {
    $_flags = ['flags', $flags.join(', '), ';'].join(' ')
  }
  $target = "015-sets/${af}/${table}"
  $content = "table ${af} ${table} { set ${setname} { type ${type}; ${_flags} }; }"

  ensure_resource('nft::file', $target, { })
  nft::fragment { "chains/${af}/${table}/${setname}":
    target  => $target,
    content => $content,
  }
}
