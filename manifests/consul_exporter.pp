# @summary This module manages prometheus node consul_exporter
# @param arch
#  Architecture (amd64 or i386)
# @param bin_dir
#  Directory where binaries are located
# @param consul_server
#  HTTP API address of a Consul server or agent. (prefix with https:// to connect over HTTPS) (default "http://localhost:8500")
# @param consul_health_summary
#  Generate a health summary for each service instance. Needs n+1 queries to collect all information. (default true)
# @param download_extension
#  Extension for the release binary archive
# @param download_url
#  Complete URL corresponding to the where the release binary archive can be downloaded
# @param download_url_base
#  Base URL for the binary archive
# @param extra_groups
#  Extra groups to add the binary user to
# @param extra_options
#  Extra options added to the startup command
# @param group
#  Group under which the binary is running
# @param init_style
#  Service startup scripts style (e.g. rc, upstart or systemd)
# @param install_method
#  Installation method: url or package (only url is supported currently)
# @param log_level
#  Only log messages with the given severity or above. Valid levels: [debug, info, warn, error, fatal] (default "info")
# @param manage_group
#  Whether to create a group for or rely on external code for that
# @param manage_service
#  Should puppet manage the service? (default true)
# @param manage_user
#  Whether to create user or rely on external code for that
# @param os
#  Operating system (linux is the only one supported)
# @param package_ensure
#  If package, then use this for package ensure default 'latest'
# @param package_name
#  The binary package name - not available yet
# @param purge_config_dir
#  Purge config files no longer generated by Puppet
# @param restart_on_change
#  Should puppet restart the service on configuration change? (default true)
# @param service_enable
#  Whether to enable the service from puppet (default true)
# @param service_ensure
#  State ensured for the service (default 'running')
# @param service_name
#  Name of the consul exporter service (default 'consul_exporter')
# @param user
#  User which runs the service
# @param version
#  The binary release version
# @param web_listen_address
#  Address to listen on for web interface and telemetry. (default ":9107")
# @param web_telemetry_path
#  Path under which to expose metrics. (default "/metrics")
class prometheus::consul_exporter (
  Boolean $consul_health_summary,
  String[1] $consul_server,
  String $download_extension,
  String[1] $download_url_base,
  Array $extra_groups,
  String[1] $group,
  String[1] $log_level,
  String[1] $package_ensure,
  String[1] $package_name,
  String[1] $service_name,
  String[1] $user,
  String[1] $version,
  String[1] $web_listen_address,
  String[1] $web_telemetry_path,
  Boolean $purge_config_dir               = true,
  Boolean $restart_on_change              = true,
  Boolean $service_enable                 = true,
  Stdlib::Ensure::Service $service_ensure = 'running',
  Boolean $manage_group                   = true,
  Boolean $manage_service                 = true,
  Boolean $manage_user                    = true,
  String[1] $os                           = downcase($facts['kernel']),
  Prometheus::Initstyle $init_style       = $facts['service_provider'],
  Prometheus::Install $install_method     = $prometheus::install_method,
  String $extra_options                   = '',
  Optional[String] $download_url          = undef,
  String[1] $arch                         = $prometheus::real_arch,
  String[1] $bin_dir                      = $prometheus::bin_dir,
  Boolean $export_scrape_job              = false,
  Optional[Stdlib::Host] $scrape_host     = undef,
  Stdlib::Port $scrape_port               = 9107,
  String[1] $scrape_job_name              = 'consul',
  Optional[Hash] $scrape_job_labels       = undef,
) inherits prometheus {
  # Prometheus added a 'v' on the realease name at 0.3.0
  if versioncmp ($version, '0.3.0') == -1 {
    fail("I only support consul_exporter version '0.3.0' or higher")
  }

  $real_download_url = pick($download_url,"${download_url_base}/download/v${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")

  if $consul_health_summary {
    if versioncmp ($version, '0.4.0') == -1 {
      $real_consul_health_summary = '-consul.health-summary'
    } else {
      $real_consul_health_summary = '--consul.health-summary'
    }
  } else {
    $real_consul_health_summary = ''
  }

  $notify_service = $restart_on_change ? {
    true    => Service[$service_name],
    default => undef,
  }

  if versioncmp ($version, '0.4.0') == -1 {
    $options = "-consul.server=${consul_server} ${real_consul_health_summary} -web.listen-address=${web_listen_address} -web.telemetry-path=${web_telemetry_path} -log.level=${log_level} ${extra_options}"
  } else {
    $options = "--consul.server=${consul_server} ${real_consul_health_summary} --web.listen-address=${web_listen_address} --web.telemetry-path=${web_telemetry_path} --log.level=${log_level} ${extra_options}"
  }

  prometheus::daemon { 'consul_exporter':
    install_method     => $install_method,
    version            => $version,
    download_extension => $download_extension,
    os                 => $os,
    arch               => $arch,
    real_download_url  => $real_download_url,
    bin_dir            => $bin_dir,
    notify_service     => $notify_service,
    package_name       => $package_name,
    package_ensure     => $package_ensure,
    manage_user        => $manage_user,
    user               => $user,
    extra_groups       => $extra_groups,
    group              => $group,
    manage_group       => $manage_group,
    purge              => $purge_config_dir,
    options            => $options,
    init_style         => $init_style,
    service_ensure     => $service_ensure,
    service_enable     => $service_enable,
    manage_service     => $manage_service,
    export_scrape_job  => $export_scrape_job,
    scrape_host        => $scrape_host,
    scrape_port        => $scrape_port,
    scrape_job_name    => $scrape_job_name,
    scrape_job_labels  => $scrape_job_labels,
  }
}
