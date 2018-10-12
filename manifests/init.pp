# == Class: bind
#
# Installs bind in a chroot and runs the named service
# configuration file variables are kept in hiera and zone
# file data is retrieved from an external source and hiera data.
#
# === Parameters
#
# $data_src: URL for external data, IPs and hostnames
# $data_name: Name for the api to connect to
# $data_key: Token to use when connecting to the api
# $bind_doamins: Hash of domain information used to popuplate named.conf
# $bind_zones: Has of zone information used to populate zone files
#
# === Examples
#
# Hiera domain data
# 
#bind::domains:
#  example.net:
#    type: master
#    slave:
#      - 10.1.16.13
#  16.1.10.in-addr.arpa:
#    type: master
#    slave:
#      - 10.1.16.13
#  0.1.10.in-addr.arpa:
#    type: master
#    CIDR: 22
#    slave:
#      - 10.1.16.13
#
# Hiera zone data
#
#bind::zones:
#  example.net:
#    ttl: 3600
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
#    data:
#      'foo': bar.example.net.
#      'ns1': 10.1.16.10
#      'ns2': 10.1.16.13
#      'sleep': pillow.other.net.
#  16.1.10.in-addr.arpa:
#    ttl: 3600
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
#
#  0.1.10.in-addr.arpa:
#    ttl: 3600
#    CIDR: 22
#    nameservers:
#      - ns1.example.net
#      - ns2.example.net
# === Authors
#
# Doug Morris <dmorris@covermymeds.com
#
# === Copyright
#
# Copyright 2015 CoverMyMeds, unless otherwise noted
#
class bind (
  Hash                  $acls,
  String                $bind_ip = $::ipaddress,
  Hash                  $domains,
  Hash                  $zones,
  Boolean               $use_ipam = true,
  Variant[String,Undef] $data_key = undef,
  Variant[String,Undef] $data_name = undef,
  Variant[String,Undef] $data_src = undef,
) {
  package{ ['bind', 'bind-utils', 'bind-chroot']:
    ensure => present,
  }

  if $use_ipam {
    validate_string($data_key)
    validate_string($data_name)
    validate_string($data_src)
  }

  $_zone_defaults = {
    'ttl'         => 3600,
    'refresh'     => 10800,
    'retry'       => 3600,
    'expire'      => 604800,
    'negresp'     => 300,
    'cidr'        => 24,
    'nameservers' => undef,
  }

  $_fwd_zone_defaults = {
    'type'        => undef,
    'data'        => undef,
  }

  $zones.each | $zone, $zone_options | {
    # Get type of server slave or master
    $type_data = $::bind::domains[$zone]['type']

    if $type_data == 'master' {
      # Check if this is a reverse zone
      if $zone =~ /^(\d+).*arpa$/ {
        bind::ptr_zone { $zone:
          * => $_zone_defaults + $zone_options,
        }
      }
      else {
        bind::fwd_zone { $zone:
          * => $_zone_defaults + $_fwd_zone_defaults + $zone_options,
        }
      }
    }
  }
}
