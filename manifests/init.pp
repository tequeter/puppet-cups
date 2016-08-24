# Class 'cups'
#
class cups (
  $confdir                = '/etc/cups',
  $debug_logging          = undef,
  $default_queue          = undef,
  $hiera                  = undef,
  $packages               = $::cups::params::packages,
  $papersize              = undef,
  $purge_unmanaged_queues = false,
  $remote_admin           = undef,
  $remote_any             = undef,
  $resources              = undef,
  $services               = $::cups::params::services,
  $share_printers         = undef,
  $user_cancel_any        = undef,
  $webinterface           = undef,
) inherits cups::params {

  ## Package installation

  if ($packages == undef) {
    fail('Please provide the name(s) of the CUPS package(s) for your operating system to Class[::cups] or set `packages => []` to disable CUPS package management.') # lint:ignore:140chars
  } else {
    validate_array($packages)

    package { $packages :
      ensure  => 'present',
    }
  }

  ## Service installation and configuration

  if ($services == undef) {
    fail('Please provide the name(s) of the CUPS service(s) for your operating system to Class[::cups] or set `services => []` to disable CUPS service management.') # lint:ignore:140chars
  } else {
    validate_array($services)

    service { $services :
      ensure  => 'running',
      enable  => true,
      require => Package[$packages],
    }
  }

  Cups::Ctl {
    require => Service[$services],
  }

  unless ($debug_logging == undef) {
    validate_bool($debug_logging)

    cups::ctl { '_debug_logging':
      ensure  => bool2str($debug_logging, '1', '0'),
    }
  }

  unless ($papersize == undef) {
    class { '::cups::papersize':
      papersize => $papersize,
      require   => Package[$packages],
      notify    => Service[$services],
    }
  }

  unless ($remote_admin == undef) {
    validate_bool($remote_admin)

    cups::ctl { '_remote_admin':
      ensure  => bool2str($remote_admin, '1', '0'),
    }
  }

  unless ($remote_any == undef) {
    validate_bool($remote_any)

    cups::ctl { '_remote_any':
      ensure  => bool2str($remote_any, '1', '0'),
    }
  }

  unless ($share_printers == undef) {
    validate_bool($share_printers)

    cups::ctl { '_share_printers':
      ensure  => bool2str($share_printers, '1', '0'),
    }
  }

  unless ($user_cancel_any == undef) {
    validate_bool($user_cancel_any)

    cups::ctl { '_user_cancel_any':
      ensure  => bool2str($user_cancel_any, '1', '0'),
    }
  }

  unless ($webinterface == undef) {
    validate_bool($webinterface)

    cups::ctl { 'WebInterface' :
      ensure  => bool2str($webinterface, 'Yes', 'No'),
    }
  }

  ## Remove special file with default settings for localhost jobs

  validate_absolute_path($confdir)
  file { 'lpoptions' :
    ensure  => 'absent',
    path    => "${confdir}/lpoptions",
    require => Service[$services],
  }

  ## Manage `cups_queue` resources

  unless ($hiera == undef) {
    validate_string($hiera)

    case $hiera {
      'priority': { create_resources('cups_queue', hiera('cups_queue')) }
      'merge': { create_resources('cups_queue', hiera_hash('cups_queue')) }
      default: { fail("Unsupported value 'hiera => ${hiera}'.") }
    }
  }

  unless ($resources == undef) {
    validate_hash($resources)

    create_resources('cups_queue', $resources)
  }

  unless ($default_queue == undef) {
    class { '::cups::default_queue' :
      queue   => $default_queue,
      require => File['lpoptions'],
    }
  }

  validate_bool($purge_unmanaged_queues)
  resources { 'cups_queue':
    purge   => $purge_unmanaged_queues,
    require => Service[$services],
  }

}
