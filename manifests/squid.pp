# == Class: frontier::squid
#
# Installation and configuration of a frontier squid
#
# === Parameters
#
# [*customize_file*]
#   The customization config file to be used.
#
# [*customize_template*]
#   The customization config template to be used (default customize.sh.erb).
#
# [*cache_dir*]
#   The cache directory.
#
# [*daemons*]
#   The number of squid daemons to run (default 1).
#
# [*cache_size*]
#   The maximum size of the cache (default 10000 KB).
#
# [*max_access_log*]
#   The max size of the log before rotating them
#
# [*install_resource*]
#   The cache directory.
#
# [*resource_path*]
#   The cache directory.
#
# === Examples
#
#  class { frontier::squid:
#    customize_file => 'puppet:///modules/mymodule/customize.sh',
#    cache_dir      => '/var/squid/cache'
#  }
#
# === Authors
#
# Alessandro De Salvo <Alessandro.DeSalvo@roma1.infn.it>
#
# Contributions from Preslav Konstantinov
#
# === Copyright
#
# Copyright 2014 Alessandro De Salvo
#
class frontier::squid (
  $customize_file = undef,
  $customize_template = "frontier/$frontier::params::frontier_customize_template",
  $cache_size = $frontier::params::frontier_cache_size,
  $cache_dir = $frontier::params::frontier_cache_dir,
  $max_access_log = undef,
  $daemons = 1,
  $install_resource = false,
  $resource_path = $frontier::params::resource_agents_path
) inherits params {
  yumrepo {'cern-frontier':
      descr => 'Frontier packages repo at CERN',
      baseurl => 'http://frontier.cern.ch/dist/rpms/',
      enabled => 1,
      gpgcheck => 1,
      gpgkey   => 'http://frontier.cern.ch/dist/rpms/cernFrontierGpgPublicKey'
  }

  package {$frontier::params::frontier_packages:
      ensure  => latest,
      require => Yumrepo['cern-frontier'],
      notify  => Service[$frontier::params::frontier_service]
  }

  define cache_subdirs ( $count, $cache_dir ) {
    $minus1 = inline_template('<%= @count.to_i - 1 %>')
    file { "${cache_dir}/squid${$minus1}":
      ensure  => directory,
      owner   => squid,
      group   => squid,
      mode    => 0755,
    }
    if ( $minus1 > 0 ) {
      cache_subdirs { "count-${minus1}":
        cache_dir => $cache_dir,
        count => $minus1,
      }
    }
  }

  if ($cache_dir) {
      file { $cache_dir:
          ensure  => directory,
          owner   => squid,
          group   => squid,
          mode    => 0755,
          require => Package[$frontier::params::frontier_packages],
          notify  => Service[$frontier::params::frontier_service]
      }

      if ( $daemons > 1 ) {
        cache_subdirs { 'start':
          cache_dir => $cache_dir,
          count => $daemons
        }
      }
  }

  if ($customize_file) {
      file {$frontier::params::frontier_customize:
          ensure  => file,
          owner   => squid,
          group   => squid,
          mode    => 0755,
          source  => $customize_file,
          require => Package[$frontier::params::frontier_packages],
          notify  => Service[$frontier::params::frontier_service]
      }
  }

  if ($customize_template) {
      file {$frontier::params::frontier_customize:
          ensure  => file,
          owner   => squid,
          group   => squid,
          mode    => 0755,
          content => template($customize_template),
          require => Package[$frontier::params::frontier_packages],
          notify  => Service[$frontier::params::frontier_service]
      }
  }

  if ($install_resource) {
      file { $resource_path:
          ensure  => directory,
          owner   => "root",
          group   => "root",
          mode    => 0755,
      }

      file { "${resource_path}/FrontierSquid":
          ensure  => file,
          owner   => "root",
          group   => "root",
          mode    => 0755,
          source  => "puppet:///modules/frontier/FrontierSquid",
          require => File[$resource_path]
      }
  }

  file {$frontier::params::frontier_squidconf:
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 0644,
      content => template('frontier/squidconf.erb'),
      require => Package[$frontier::params::frontier_packages],
  }

  service {$frontier::params::frontier_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package[$frontier::params::frontier_packages]
  }
}
