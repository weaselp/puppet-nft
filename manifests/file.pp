# Create a chain for nft to stage content in
#
# This is a module internal type, you should never need to use it from outside.
#
# @param filename  Base name of the file (without path or extension)
# @param content   Content to start the file with
# @param extension String to append to the filename
define nft::file(
  String $filename = regsubst($name, '[^a-zA-Z0-9.,_=-]', '_' ,'G'),
  Optional[String] $content = undef,
  String $extension = '.nft',
) {
  include nft

  $filename_test = "${nft::dir_test}/${filename}${extension}"
  $filename_prod = "${nft::dir_prod}/${filename}${extension}"

  concat { "nft::file::${filename}":
    path           => $filename_test,
    mode           => '0444',
    owner          => 'root',
    group          => 'root',
    ensure_newline => true,
    order          => 'numeric',
    warn           => @("EOF"),
      # This file is managed by Puppet.  Do not edit it here.
      ${content}
      | EOF
  }
  ~> Exec['nft check']
  -> file { $filename_prod:
    mode   => '0444',
    owner  => 'root',
    group  => 'root',
    source => $filename_test,
  }
  ~> Service['nftables']
}
