# Class: dovecot
#
# Install, enable and configure the Dovecot IMAP server.
# Options:
#  $plugins:
#    Array of plugin sub-packages to install. Default: empty
#
class dovecot (
    # Backports Debian only!
    $backports                     = false,

    $plugins                       = [],
    # dovecot.conf
    $protocols                     = undef,
    $listen                        = undef,
    $login_greeting                = undef,
    $login_trusted_networks        = undef,
    $verbose_proctitle             = undef,
    $shutdown_clients              = undef,
    # 10-auth.conf
    $disable_plaintext_auth        = undef,
    $auth_username_chars           = undef,
    $auth_username_format          = undef,
    $auth_master_separator         = '*',
    $auth_mechanisms               = 'plain',
    $auth_include                  = [ 'system' ],
    $auth_cache_size               = undef,
    $auth_cache_ttl                = undef,
    $auth_cache_negative_ttl       = undef,
    # 10-logging.conf
    $log_path                      = undef,
    $log_timestamp                 = undef,
    $auth_verbose                  = undef,
    $auth_debug                    = undef,
    $mail_debug                    = undef,
    # 10-mail.conf
    $mail_location                 = undef,
    $inbox_separator               = undef,
    $inbox_prefix                  = undef,
    $mmap_disable                  = undef,
    $dotlock_use_excl              = undef,
    $mail_fsync                    = undef,
    $mail_nfs_storage              = undef,
    $mail_nfs_index                = undef,
    $first_valid_uid               = false,
    $last_valid_uid                = false,
    $mail_plugins                  = undef,
    $mdbox_rotate_size             = undef,
    # 10-master.conf
    $default_process_limit         = undef,
    $default_client_limit          = undef,
    $auth_listener_userdb_mode     = undef,
    $auth_listener_userdb_user     = undef,
    $auth_listener_userdb_group    = undef,
    $auth_listener_postfix         = false,
    $lmtp_inet_listener            = false,
    $lmtp_address                  = '127.0.0.1',
    $lmtp_port                     = '24',
    $lmtp_socket_path              = undef,
    # 10-ssl.conf
    $ssl                           = undef,
    $ssl_cert                      = '/etc/pki/dovecot/certs/dovecot.pem',
    $ssl_key                       = '/etc/pki/dovecot/private/dovecot.pem',
    $ssl_cipher_list               = undef,
    # 15-lda.conf
    $postmaster_address            = undef,
    $hostname                      = undef,
    $lda_mail_plugins              = undef,
    # 20-imap.conf
    $mail_max_userip_connections   = undef,
    $imap_mail_plugins             = undef,
    # 20-lmtp.conf
    $lmtp_mail_plugins             = undef,
    # 90-sieve.conf
    $sieve                         = '~/.dovecot.sieve',
    $sieve_default                 = undef,
    $sieve_dir                     = '~/sieve',
    $sieve_global_dir              = undef,
    $sieve_extensions              = undef,
    # 90-plugin.conf
    $plugin_conf                   = {},
    # auth-sql.conf.ext
    $auth_sql_userdb_static        = undef,
    # auth-system.conf.ext
    $userdb_passwd_override_fields = undef,
    # auth-master.conf.ext / master-users
    $auth_master_pass              = false,
    $master_users                  = '',
    # auth-ldap.conf.ext
    $ldap_prefetch                 = undef,
    # dovecot-ldap.conf.ext
    $ldap_uris                     = undef,
    $ldap_dn                       = undef,
    $ldap_dnpass                   = undef,
    $ldap_auth_bind                = undef,
    $ldap_base                     = undef,
    $ldap_user_attrs               = undef,
    $ldap_user_filter              = undef,
    $ldap_pass_attrs               = undef,
    $ldap_pass_filter              = undef,
    $ldap_iterate_attrs            = undef,
    $ldap_iterate_filter           = undef,
) {

    case $::operatingsystem {
      'RedHat', 'CentOS': {
        $packages = 'dovecot'
      }
      /^(Debian|Ubuntu)$/:{
        $packages = ['dovecot-core','dovecot-imapd', 'dovecot-pop3d', 'dovecot-mysql', 'dovecot-lmtpd']
      }
      default: {
        fail("OS ${::operatingsystem} and version ${::operatingsystemrelease} is not supported")
      }
    }

    # All files in this scope are dovecot configuration files
    File {
        notify  => Service['dovecot'],
        require => Package[$packages],
    }

    # DEBIAN only!
    if $::osfamily == 'Debian' {

      #If we want to have dovecot from Debian Backpots:
      if $dovecot::backports {
        include apt::backports

        $release = downcase($::lsbdistcodename)
        apt::pin { 'pin_dovecot_release':
          packages => 'dovecot-*',
          release  => "${release}-backports",
          priority => '995',
        }

        Class['apt::backports']
        -> Package<| tag == 'dovecot-packages' |>
      }

    }

    # Install plugins (sub-packages)
    dovecot::plugin { $plugins: require => Package[$packages] }

    # Main package and service it provides
    package { $packages:
        ensure => latest,
        tag    => 'dovecot-packages',
    }
    service { 'dovecot':
        ensure    => running,
        enable    => true,
        hasstatus => true,
        require   => File['/etc/dovecot/dovecot.conf'],
    }

    # Main configuration file
    file { '/etc/dovecot/dovecot.conf':
        content => template('dovecot/dovecot.conf.erb'),
    }

    # Configuration file snippets which we modify
    file { '/etc/dovecot/conf.d/10-auth.conf':
        content => template('dovecot/conf.d/10-auth.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/10-logging.conf':
        content => template('dovecot/conf.d/10-logging.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/10-mail.conf':
        content => template('dovecot/conf.d/10-mail.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/10-master.conf':
        content => template('dovecot/conf.d/10-master.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/10-ssl.conf':
        content => template('dovecot/conf.d/10-ssl.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/15-lda.conf':
        content => template('dovecot/conf.d/15-lda.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/20-imap.conf':
        content => template('dovecot/conf.d/20-imap.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/20-lmtp.conf':
        content => template('dovecot/conf.d/20-lmtp.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/90-sieve.conf':
        content => template('dovecot/conf.d/90-sieve.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/90-plugin.conf':
        content => template('dovecot/conf.d/90-plugin.conf.erb'),
    }
    file { '/etc/dovecot/conf.d/auth-sql.conf.ext':
        content => template('dovecot/conf.d/auth-sql.conf.ext.erb'),
    }
    file { '/etc/dovecot/conf.d/auth-system.conf.ext':
        content => template('dovecot/conf.d/auth-system.conf.ext.erb'),
    }
    file { '/etc/dovecot/conf.d/auth-master.conf.ext':
        content => template('dovecot/conf.d/auth-master.conf.ext.erb'),
    }
    file { '/etc/dovecot/conf.d/auth-ldap.conf.ext':
        content => template('dovecot/conf.d/auth-ldap.conf.ext.erb'),
    }

    dovecot::file {'dovecot-ldap.conf.ext':
      group   => dovecot,
      mode    => '0640',
      content => template('dovecot/dovecot-ldap.conf.ext.erb')
    }

    # file with master users
    dovecot::file {'master-users':
      group   => dovecot,
      mode    => '0640',
      content => $master_users,
    }

}

