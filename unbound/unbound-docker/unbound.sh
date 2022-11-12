#!/bin/bash
set -x

cat <<EOT >> /opt/unbound/etc/unbound/unbound.conf
server:
  directory: "/opt/unbound/etc/unbound"
  username: "unbound"
  num-threads: 4
  verbosity: 1
  chroot: "/opt/unbound/etc/unbound"
  pidfile: "/opt/unbound/etc/unbound.pid"
  logfile: "/opt/unbound/etc/unbound/unbound.log"
  ssl-service-key: "/opt/unbound/etc/unbound/dnsPrivate.key"
  ssl-service-pem: "/opt/unbound/etc/unbound/unbound_dns.crt"
  auto-trust-anchor-file: "/opt/unbound/etc/unbound/var/root.key"
  interface: 0.0.0.0@853
  ssl-port: 853
  so-reuseport: yes
  do-daemonize: no
  num-queries-per-thread: 4096
  outgoing-range: 8192
  access-control: 0.0.0.0/0 allow
  hide-version: yes
  hide-identity: yes
  do-ip4: yes
  do-ip6: no
  harden-dnssec-stripped: yes
  private-address: 192.168.0.0/16
  private-address: 172.16.0.0/12
  private-address: 10.0.0.0/8
  private-address: 169.254.0.0/16
  # Cipher setting for newer TLS 1.3 connections.
  # Set the list of ciphersuites to allow when serving TLS. 
  # Use "" for defaults, and that is the default.
  # tls-ciphersuites: "TLS_CHACHA20_POLY1305_SHA256"
  # tls-ciphersuites: "bikel1"
EOT

ldd /opt/unbound/sbin/unbound
openssl version -a
mkdir -p -m 700 /opt/unbound/etc/unbound/var
chown unbound:unbound /opt/unbound/etc/unbound/var
/opt/unbound/sbin/unbound-anchor -a "/opt/unbound/etc/unbound/var/root.key"
touch /opt/unbound/etc/unbound/unbound.log
chown unbound:unbound /opt/unbound/etc/unbound/unbound.log
exec /opt/unbound/sbin/unbound -V
exec export TLS_DEFAULT_GROUPS="p384_kyber768:X25519"

