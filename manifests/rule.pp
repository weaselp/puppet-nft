# Create a rule in our nftables config
#
# Rules live in chains that belong to tables.  Confer to the nftables
# documentation for how to write rules.  Also see nft::simple for a more
# abstracted way of adding rules.
#
# @param rule         The actual nftables rule.
# @param chain        The name of the chain
# @param af           Address family (inet, ip, ip6, etc)
# @param table        The name of the table
# @param description  A description or comment for this rule to put into the nftables config
# @param order        Where to put this rule in the concat file
#
# @example
#   nft::chain{ 'input': }
#   nft::chain{ 'services_tcp': }
#
#   nft::rule{
#     'iif lo counter accept': order => 100;
#     'meta l4proto icmp counter accept': order => 101;
#     'meta l4proto ipv6-icmp counter accept': order => 101;
#     'ct state established,related counter accept': order => 110;
#     'meta l4proto tcp counter jump services_tcp': order => 20;
#     'counter drop': order => 9000;
#   }
#
#   nft::rule{ 'allow-https':
#     rule  => 'tcp dport https counter accept',
#     chain => 'services_tcp',
#   }
#
define nft::rule (
  Variant[String,Array[String]] $rule = $name,
  Nft::String        $chain = 'input',
  Nft::AddressFamily $af = 'inet',
  Nft::String        $table = 'filter',
  Optional[String]       $description = undef,
  Integer                $order = 200,
) {
  if $rule =~ Array[String,2] {
    $joined_rule = ['', ($rule + [''])].join(";\n  ")
  } else {
    $_element = Array($rule, true)[0]
    $joined_rule = "${_element}; "
  }
  nft::fragment { $name:
    target  => "050-rules/${af}/${table}/${chain}",
    content => delete_undef_values([
      if $description =~ Undef { "# nrf_nft::rule ${name}" }
        elsif $description != '' { "# ${description}" }
        else { undef },
      "table ${af} ${table} { chain ${chain} { ${joined_rule}}; }"
      ]).join("\n"),
    order   => $order,
  }
}
