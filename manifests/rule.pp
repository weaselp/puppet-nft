# Create a rule in our nftables config
#
# Rules live in chains that belong to tables.  Confer to the nftables documentation
# for how to write rules.
#
# @param rule         The actual nftables rule.
# @param chain        The name of the chain
# @param af           Address family (inet, ip, ip6, etc)
# @param table        The name of the table
# @param description  A description or comment for this rule to put into the nftables config
# @param order        Where to put this rule in the concat file
#
# Example;
#   nry_nft::chain{ 'input': }
#   nry_nft::chain{ 'services_tcp': }
#
#   nry_nft::rule{
#     'iif lo counter accept': order => 100;
#     'meta l4proto icmp counter accept': order => 101;
#     'meta l4proto ipv6-icmp counter accept': order => 101;
#     'ct state established,related counter accept': order => 110;
#     'meta l4proto tcp counter jump services_tcp': order => 20;
#     'counter drop': order => 9000;
#   }
#
#   nry_nft::rule{ 'allow-https':
#     rule  => 'tcp dport https counter accept',
#     chain => 'services_tcp',
#   }
#
define nry_nft::rule(
  Variant[String,Array[String]] $rule = $name,
  Nry_nft::String        $chain = 'input',
  Nry_nft::AddressFamily $af = 'inet',
  Nry_nft::String        $table = 'filter',
  Optional[String]       $description = undef,
  Integer                $order = 200,
) {
  $joined_rule = Array($rule, true).join(";\n")
  nry_nft::fragment { "nry_nft::rule::${name}":
    target  => "050-rules/${af}/${table}/${chain}",
    content => delete_undef_values([
      if $description =~ Undef { "# nrf_nft::rule ${name}" }
        elsif $description != '' { "# ${description}" }
        else { undef },
      "table ${af} ${table} { chain ${chain} { ${joined_rule}; }; }"
      ]).join("\n"),
    order   => $order,
  }
}
