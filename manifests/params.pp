class frontier::params {

  case $::osfamily {
    'RedHat': {
      $frontier_release_provider = 'rpm'
      $frontier_release_package = 'frontier-release-1.0-1.noarch.rpm'
      $frontier_release_package_url = "http://frontier.cern.ch/dist/rpms/RPMS/noarch/${frontier_release_package}"
      $frontier_packages = ['frontier-squid']
      $frontier_service = 'frontier-squid'
      $frontier_customize = '/etc/squid/customize.sh'
      $frontier_customize_template = 'customize.sh.erb'
      $frontier_squidconf = '/etc/sysconfig/frontier-squid'
      $frontier_cache_dir = '/var/cache/squid'
      $frontier_cache_size = 10000
      $resource_agents_path = '/usr/lib/ocf/resource.d/lcg'
    }
    default:   {
    }
  }

}
