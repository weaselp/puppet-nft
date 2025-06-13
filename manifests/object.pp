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
define nft::object (
  Nft::Objectdefine $object_name = $name,
  Array[String] $elements = [],
) {
  # Figure out address family of directly included elements
  $_non_objects_refs = $elements.filter |$a| { $a !~ Nft::Objectreference }
  $_ip4           = $_non_objects_refs.filter |$a| { $a =~ Stdlib::IP::Address::V4 }
  $_ip6           = $_non_objects_refs.filter |$a| { $a =~ Stdlib::IP::Address::V6 }
  $_non_addresses = $_non_objects_refs.filter |$a| { $a !~ Stdlib::IP::Address::V4 and $a !~ Stdlib::IP::Address::V6 }

  # Figure out address family of included objects
  $_object_refs = $elements.filter |$a| { $a =~ Nft::Objectreference }
  $_obj_af_info = Hash($_object_refs.map |$o| {
      $object_ref_name = $o.regsubst(/^\$/, '')
      $object = Nft::Object_impl[$object_ref_name]
      [$object_ref_name,
        {
          has_v4        => $object['have_ipv4'],
          has_v6        => $object['have_ipv6'],
          include_level => $object['include_level'],
        },
      ]
  })
  $_objects_v4       = $_obj_af_info.filter |$object_name, $object_info| { $object_info['has_v4'] }
  $_objects_v6       = $_obj_af_info.filter |$object_name, $object_info| { $object_info['has_v6'] }
  $_objects_non_addr = $_obj_af_info.filter |$object_name, $object_info| { !$object_info['has_v4'] and !$object_info['has_v6'] }
  $_include_level    = ([0] + $_obj_af_info.map |$object_name, $object_info| { $object_info['include_level'] + 1 }).max

  # Figure out our address family
  $have_ipv4 = $_ip4.length() > 0 or $_objects_v4.length() > 0
  $have_ipv6 = $_ip6.length() > 0 or $_objects_v6.length() > 0

  nft::object_impl { $object_name:
    object_name       => $object_name,
    ipv4_elements     => $_ip4,
    ipv6_elements     => $_ip6,
    non_addr_elements => $_non_addresses,

    ipv4_objects      => $_objects_v4.keys(),
    ipv6_objects      => $_objects_v6.keys(),
    non_addr_objects  => $_objects_non_addr.keys(),

    have_ipv4         => $_ip4.length() > 0 or $_objects_v4.length() > 0,
    have_ipv6         => $_ip6.length() > 0 or $_objects_v6.length() > 0,

    include_level     => $_include_level,
  }
}
