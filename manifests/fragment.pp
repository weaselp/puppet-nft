# Add a fragment to a staging file created by nft::file
#
# This is a module internal type, you should never need to use it from outside.
#
# @param target   Where in our nftables config this should end up with.
#                 Usually this is a per-chain file.
# @param source   Source to pass to concat::fragment
# @param content  Content to pass to concat::fragment
# @param order    Order to pass to concat::fragment
define nft::fragment(
  String $target,
  Optional[String] $source = undef,
  Optional[String] $content = undef,
  Optional[Integer] $order = undef,
) {
  concat::fragment { "nft::fragment::${name}":
    target  => "nft::file::${target}",
    content => $content,
    source  => $source,
    order   => $order,
  }
}
