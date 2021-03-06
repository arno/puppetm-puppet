# == Class: puppet::server
#
# This subclass manages all the configuration required for Puppet Server
#
# === Authors:
#
# Julien Georges
#
class puppet::server (
    $passenger       = false,
    $environmentpath = '$confdir/environments',
    $external_nodes  = '/usr/local/bin/puppet_node_classifier',
    $certname        = $::fqdn,
    $dns_alt_names   = undef,
    $ca_master       = true,
    $ssldir          = undef,
) inherits puppet {

    # If we enable passenger mode, we must stop puppetmaster service
    if $passenger {
        $enable = false
        $ensure = 'stopped'
    }else{
        $enable = true
        $ensure = 'running'
    }

    package { 'puppet-server':
        ensure => present,
    } ->
    concat::fragment { 'master':
        target  => '/etc/puppet/puppet.conf',
        content => template('puppet/master.erb'),
        order   => '30',
    } ->
    # We first need to start the puppetmaster to generate the ssl certs
    exec { 'create_server_certificates':
        command => '/bin/systemctl restart puppetmaster;
                    /usr/bin/sleep 10',
        unless  => "/bin/ls ${ssldir}/private_keys/${certname}.pem",
        require => Class['puppet::config'],
    } ->
    service { 'puppetmaster':
        enable  => $enable,
        ensure  => $ensure,
    }

}
