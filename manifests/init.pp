# Initialize nft, the noreply nftables puppet module.
#
# This sets up the staging directory and files and installs nftables
# and activates the service.  No policy is shipped with this module,
# it needs to be provided by other puppet code using nft.
#
# @param dir_test  Staging directory
# @param dir_prod  Production directory for the live, tested rules
# @param main_test Staging config file that sources everything else
# @param main_prod Production config file that sources everything else
#
# @param flush_ruleset
#   Whether to flush the ruleset at the start, or which tables to flush.
#   In general, this probably always wants to be true.  However, if you manage
#   for instance the inet table with this module and say the ip table by some
#   other means, this can be set to just 'inet'.
#
# @param service_enable  enable the nftables service
# @param service_ensure  whether to have the service running or stopped
class nft(
  Stdlib::AbsolutePath $dir_test = '/etc/.nftables-staging',
  Stdlib::AbsolutePath $dir_prod = '/etc/nftables',

  Stdlib::AbsolutePath $main_test = "${dir_test}/main.conf",
  Stdlib::AbsolutePath $main_prod = $facts['os']['family'] ? {
    'Debian' => '/etc/nftables.conf',
    'RedHat' => '/etc/sysconfig/nftables.conf',
    default  => '/etc/nftables.conf',
  },
  Variant[Boolean, String] $flush_ruleset = true,

  Boolean $service_enable = true,
  Enum['running', 'stopped'] $service_ensure = if ($service_enable) { 'running' } else { 'stopped' },
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

  if $flush_ruleset =~ String {
    $_preamble = "flush ruleset ${flush_ruleset}"
  } elsif $flush_ruleset {
    $_preamble = 'flush ruleset'
  } else {
    $_preamble = ''
  }

  exec { 'nft check':
    refreshonly => true,
    command     => "/usr/sbin/nft -c -f '${nft::main_test}' || ( echo '# broken config flag' >> '${nft::main_test}' && false)",
    require     => File[$nft::main_test],
  }
  service { 'nftables':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    path       => $facts['path'],
    restart    => 'systemctl reload nftables',
    require    => File[$nft::main_prod],
  }

  file { [$nft::dir_test, $nft::dir_prod]:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    purge   => true,
    force   => true,
    recurse => true,
  }

  file { $nft::main_test:
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    content => @("EOF"),
      ${_preamble}
      include "${nft::dir_test}/*.nft"
      | EOF
  }
  ~> Exec['nft check']
  -> file { $nft::main_prod:
    mode    => '0544',
    owner   => 'root',
    group   => 'root',
    content => @("EOF"),
      #!/usr/sbin/nft -f
      # This file is managed by Puppet.  Do not edit it here.

      ${_preamble}
      include "${nft::dir_prod}/*.nft"
      | EOF
  }
  ~> Service['nftables']
}
