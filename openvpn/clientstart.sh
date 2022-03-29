#!/bin/bash

mkdir -p /dev/net
mknod /dev/net/tun c 10 200

openvpn --config /etc/openvpn/CLIENTNAME.ovpn

# KEMs chosen will be taken from the system-wide openssl.cnf file
# overrule the list by using the option --tls-groups, e.g., like this:
# openvpn --config /etc/openvpn/CLIENTNAME.ovpn --tls-groups kyber1024:X25519



