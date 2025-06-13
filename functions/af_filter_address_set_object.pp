# Find the elements of a given address family for an address, set, or object as passed into nft::simnple
#
# For object references, replace by the corresponding __<x>_ object (cf. nft::object)
#
# @param filter_element  The address, set, or list to filter
# @param test_target     v4 or v6
# @return                The addresses and sets in that list of the given address family
function nft::af_filter_address_set_object(
  Optional[
    Variant[
      Stdlib::IP::Address,
      Nft::Setreference,
      Nft::Objectreference,
      Array[
        Variant[
          Stdlib::IP::Address,
          Nft::Objectreference
        ]
      ]
    ]
  ] $filter_element,
  Enum['v4', 'v6'] $test_target,
)
>> Variant[
  Array[Variant[Stdlib::IP::Address::V4, Nft::Objectreference, Nft::Objectreference_internal]],
  Array[Variant[Stdlib::IP::Address::V6, Nft::Objectreference, Nft::Objectreference_internal]],
  Array[Nft::Setreference, 1, 1]
] {
  [$expect_class_type, $expect_set_type] = $test_target ? {
    'v4'    => [Stdlib::IP::Address::V4, 'ipv4_addr'],
    'v6'    => [Stdlib::IP::Address::V6, 'ipv6_addr'],
    default => fail('Confused about test_target'),
  }

  Array(pick($filter_element, []), true).map |$a| {
    if ($a =~ Type($expect_class_type)) or
    ($a =~ Nft::Setreference and Nft::Set[$a.regsubst(/^@/, '')]['type'] == $expect_set_type ) {
      $a
    } elsif $a =~ Nft::Objectreference {
      $object_name = $a.regsubst(/^\$/, '')
      $object = Nft::Object_impl[$object_name]
      case $test_target {
        'v4': { if $object['have_ipv4'] { "\$__4_${object_name}" } }
        'v6': { if $object['have_ipv6'] { "\$__6_${object_name}" } }
        default: { fail('Unexpected test_target case') }
      }
    }
  }.delete_undef_values()
}
