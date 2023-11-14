# Create an nftables.conf "define" set.  This is static and can then be
# referenced in other nftables like things
#
# Implicitly, we also create __4_<x> and __6_<y> objects with just the ipv4 and
# ipv6 elements of the object.  If the object is not an address object, these
# will usually be empty.
#
# @param object_name   The name of the object, in capital letters.
# @param elements
#    A list of elements in this set.
#    Currently, no syntax checking is done in the puppet module.
#
# Example:
#   nft::object{ 'SIMPLE_SET':
#     elements => [ '192.168.1.1', '192.168.1.2' ],
#   }
# Example:
#   nft::object{ 'CDN':
#     elements => [ '$CDN_EDGE', '$CDN_MONITORS' ]
#   }
define nft::object(
  Nft::Objectdefine $object_name = $name,
  Array[String] $elements = [],
) {
  $target = '005-objects'

  $ip4 = $elements.filter |$a| { $a =~ Stdlib::IP::Address::V4 }
  $ip6 = $elements.filter |$a| { $a =~ Stdlib::IP::Address::V6 }
  $object_refs = $elements.filter |$a| { $a =~ Nft::Objectreference }

  $contents = {
    $object_name        => $elements,
    "__4_${object_name}"=> $ip4 + $object_refs.map |$o| { $_o = $o.regsubst(/^\$/, ''); "\$__4_${_o}" },
    "__6_${object_name}"=> $ip6 + $object_refs.map |$o| { $_o = $o.regsubst(/^\$/, ''); "\$__6_${_o}" },
  }.map |$_name, $_elements| {
    if $_elements.length > 0 {
      $_str_elements = $_elements.join(",\n  ")
      "define ${_name} = {\n  ${_str_elements}\n  }"
    } else {
      "define ${_name} = {}"
    }
  }

  ensure_resource('nft::file', $target, { })
  nft::fragment { "chains/${object_name}":
    target  => $target,
    content => $contents.join("\n"),
  }
}
