# Initialize nry_nft, the noreply nftables puppet module.
#
# This sets up the staging directory and files and installs nftables
# and activates the service.  No policy is shipped with this module,
# it needs to be provided by other puppet code using nry_nft.
#
# @param dir_test  Staging directory
# @param dir_prod  Production directory for the live, tested rules
# @param main_test Staging config file that sources everything else
# @param main_prod Production config file that sources everything else
class nry_nft(
  Stdlib::AbsolutePath $dir_test = '/etc/.nftables-staging',
  Stdlib::AbsolutePath $dir_prod = '/etc/nftables',

  Stdlib::AbsolutePath $main_test = "${dir_test}/main.conf",
  Stdlib::AbsolutePath $main_prod = $facts['os']['family'] ? {
    'Debian' => '/etc/nftables.conf',
    'RedHat' => '/etc/sysconfig/nftables.conf',
    default  => '/etc/nftables.conf',
  }
) {
  package { 'nftables':
    ensure => installed,
  }

  if $facts['os']['family'] == 'RedHat' {
    service{'firewalld':
      ensure => 'stopped',
      enable => false,
    }
  }

  exec { 'nft check':
    refreshonly => true,
    command     => "/usr/sbin/nft -c -f '${nry_nft::main_test}' || ( echo '# broken config flag' >> '${nry_nft::main_test}' && false)",
    require     => File[$nry_nft::main_test],
  }
  service { 'nftables':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    restart    => '/usr/bin/systemctl reload nftables',
    require    => File[$nry_nft::main_prod],
  }

  file { [$nry_nft::dir_test, $nry_nft::dir_prod]:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    purge   => true,
    force   => true,
    recurse => true,
  }

  file { $nry_nft::main_test:
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => @("EOF"),
      flush ruleset
      include "${nry_nft::dir_test}/*.nft"
      | EOF
  }
  ~> Exec['nft check']
  -> file { $nry_nft::main_prod:
    mode    => '0544',
    owner   => 'root',
    group   => 'root',
    content => @("EOF"),
      #!/usr/sbin/nft -f
      # This file is managed by Puppet.  Do not edit it here.

      flush ruleset
      include "${nry_nft::dir_prod}/*.nft"
      | EOF
  }
  ~> Service['nftables']
}
