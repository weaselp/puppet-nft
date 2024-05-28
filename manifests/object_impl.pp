# The backend implementation the nft::object front.
#
# This type knows its address types.
#
# An object may not have address elements/objects and non-adress
# elements/objects at the same time.
#
# @param object_name    The name of the object, in capital letters.
# @param ipv4_elements  IPv4 Addresses in this object
# @param ipv6_elements  IPv6 Addresses in this object
# @param ipv4_objects   IPv4 Object names referenced by this object
# @param ipv6_objects   IPv6 Object names referenced by this object
# @param non_addr_elements  Non-Address elements in this object
# @param non_addr_objects   Non-Address Object names referenced by this object
#
# @param have_ipv4  Is an object that includes ipv4 elements directly or via referenced objects
#   This must be set by the caller, as computing it here is too late since objects
#   get evaluated lazily, and when we access this by e.g. the af_filter_address_set_object
#   function, we need the correct values.
# @param have_ipv6  Is an object that includes ipv6 elements directly or via referenced objects
#   Just like have_ipv4, this must be set by the caller and for the same reasons.
#
# @param include_level
#   How many levels deep this object includes other objects.  Relevant for nft
#   file ordering.
#
# Example:
#   nft::object_impl{ 'SIMPLE_SET':
#     ipv4_elements => [ '192.168.1.1', '192.168.1.2' ],
#   }
define nft::object_impl(
  Boolean $have_ipv4,
  Boolean $have_ipv6,
  Integer $include_level,

  Nft::Objectdefine $object_name = $name,
  Array[Stdlib::IP::Address::V4] $ipv4_elements = [],
  Array[Stdlib::IP::Address::V6] $ipv6_elements = [],
  Array[String] $non_addr_elements = [],

  Array[Nft::Objectdefine] $ipv4_objects = [],
  Array[Nft::Objectdefine] $ipv6_objects = [],
  Array[Nft::Objectdefine] $non_addr_objects = [],
) {
  assert_private()
  $_target = '005-objects'

  if $have_ipv4 != ($ipv4_elements.length() > 0 or $ipv4_objects.length() > 0) {
    fail('have_ipv4 not set correctly')
  }
  if $have_ipv6 != ($ipv6_elements.length() > 0 or $ipv6_objects.length() > 0) {
    fail('have_ipv6 not set correctly')
  }
  $_have_non_addr_members = $non_addr_elements.length() > 0 or $non_addr_objects.length() > 0


  if ($ipv4_elements.length() > 0 or $ipv6_elements.length() > 0) and $non_addr_elements.length > 0 {
    fail("Object ${name}: Cannot have address and non-address elements.")
  }
  if ($ipv4_objects.length() > 0 or $ipv6_objects.length() > 0) and $non_addr_objects.length > 0 {
    fail("Object ${name}: Cannot include address and non-address objects.")
  }

  if ($have_ipv4 or $have_ipv6) and $_have_non_addr_members {
    fail("Object ${name}: cannot mix address elements/objects with non-address elements/objects")
  }

  $contents = [
    if $_have_non_addr_members { [$object_name        , $non_addr_elements + $non_addr_objects ] },
    if $have_ipv4              { ["__4_${object_name}", $ipv4_elements + $ipv4_objects.map |$o| { "\$__4_${o}" }] },
    if $have_ipv6              { ["__6_${object_name}", $ipv6_elements + $ipv6_objects.map |$o| { "\$__6_${o}" }] },
  ].delete_undef_values().map |$_tuple| {
    [$_name, $_elements] = $_tuple
    if $_elements.length > 0 {
      $_str_elements = $_elements.join(",\n  ")
      "define ${_name} = {\n  ${_str_elements}\n  }"
    } else {
      "define ${_name} = {}"
    }
  }

  ensure_resource('nft::file', $_target, { })
  nft::fragment { "chains/${object_name}":
    target  => $_target,
    content => $contents.join("\n"),
    order   => 50 + $include_level,
  }
}

