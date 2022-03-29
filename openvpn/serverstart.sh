#!/bin/bash

mkdir -p /dev/net
mknod /dev/net/tun c 10 200

openvpn --config /etc/openvpn/openvpn.conf --client-config-dir /etc/openvpn/ccd --crl-verify /etc/openvpn/pki/crl.pem 

# KEMs chosen will be taken from the system-wide openssl.cnf file
# overrule the list by using the option --tls-groups, e.g., like this:
#openvpn --config /etc/openvpn/openvpn.conf --client-config-dir /etc/openvpn/ccd --crl-verify /etc/openvpn/pki/crl.pem --tls-groups kyber1024:X25519



