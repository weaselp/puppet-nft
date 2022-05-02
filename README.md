# noreply nftables Puppet module

## Overview

This ``nft`` module provides building blocks for making an nftables firewall using puppet.
It does not come with a policy but it provides the infrastructure for building your own.

## Usage

Here's an example:

```puppet
# local noreply.org nft policies
class my_nft() {
  $log_limit_rate = '5/minute burst 5 packets'
  $reject_rate = '60/minute burst 120 packets'

  class{ 'nft': }

  nft::chain{ 'input': }
  nft::chain{ 'forward': }
  nft::chain{ 'output': }

  nft::chain{ 'services_tcp': }
  nft::chain{ 'services_udp': }

  nft::rule{
    'iif lo counter accept': order => 100;
    'meta l4proto icmp counter accept': order => 101;
    'meta l4proto ipv6-icmp counter accept': order => 101;

    'ct state established,related counter accept': order => 110;

    'meta l4proto tcp counter jump services_tcp': order => 1200;
    'meta l4proto udp counter jump services_udp': order => 1201;
    'goto log_reject_drop': order => 9900;
  }

  nft::chain{ 'log_reject_drop':
    rules => [
      "limit rate ${log_limit_rate} log flags all counter",
      "limit rate ${reject_rate} meta l4proto tcp counter reject with tcp reset",
      "limit rate ${reject_rate} meta l4proto != tcp counter reject with icmpx type admin-prohibited",
      'counter drop',
    ]
  }

  include my_nft::rule::ssh
}
```

```puppet
# Allow ssh either from everywhere or from the networks in src
#
# @param src Hosts to allow ssh connections from
class my_nft::rule::ssh(
  Optional[Array[Stdlib::IP::Address]] $src = undef,
) {
  if $src =~ Undef {
    nft::rule{ 'allow-ssh':
      rule  => 'tcp dport ssh counter accept',
      chain => 'services_tcp',
    }
  } else {
    $ip4 = $src.filter |$a| { $a !~ Stdlib::IP::Address::V6 }
    $ip6 = $src.filter |$a| { $a =~ Stdlib::IP::Address::V6 }

    nft::rule{ 'allow-ssh4':
      rule  => "tcp dport ssh ip  saddr { ${ip4.join(', ')} } counter accept",
      chain => 'services_tcp',
    }
    nft::rule{ 'allow-ssh6':
      rule  => "tcp dport ssh ip6 saddr { ${ip6.join(', ')} } counter accept",
      chain => 'services_tcp',
    }
  }
}
```

And another one:

```puppet
class mprofiles::puppetagent (
) {
# [...]
# $addresses = [...]

  # export a firewall rule to the puppet server
  @@nft::simple{ "puppet-${trusted['certname']}":
    tag   => "to-${server_facts['servername']}",
    saddr => $addresses,
    chain => 'puppetserver',
  }
}
```

```puppet
class mprofiles::puppetserver (
) {
  nft::chain{ 'puppetserver': }
  nft::rule{ 'tcp dport 8140 counter jump puppetserver': chain => 'services_tcp' }

  # Collect firewall rules exported to us
  Nft::Simple <<| tag == "to-${trusted['certname']}" |>>
}
```
