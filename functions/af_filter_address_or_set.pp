# Find the elements of a given address family for an address, set, or list of addresses.
#
# @param filter_element  The address, set, or list to filter
# @param test_target     v4 or v6
# @return                The addresses and sets in that list of the given address family
function nft::af_filter_address_or_set(
  Optional[Variant[Stdlib::IP::Address, Nft::Setreference, Array[Stdlib::IP::Address]]] $filter_element,
  Enum['v4', 'v6'] $test_target,
)
>> Variant[Array[Stdlib::IP::Address::V4], Array[Stdlib::IP::Address::V6], Array[Nft::Setreference, 1, 1]]
{
  [$expect_class_type, $expect_set_type] = $test_target ? {
    'v4'    => [Stdlib::IP::Address::V4, 'ipv4_addr'],
    'v6'    => [Stdlib::IP::Address::V6, 'ipv6_addr'],
    default => fail('Confused about test_target'),
  }

  Array(pick($filter_element, []), true).filter |$a| {
    ($a =~ Type($expect_class_type)) or
    ($a =~ Nft::Setreference and Nft::Set[ $a.regsubst(/^@/, '') ]['type'] == $expect_set_type )
  }
}
