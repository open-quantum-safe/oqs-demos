#!/bin/bash

mkdir -p /dev/net
mknod /dev/net/tun c 10 200

# KEMs chosen will be taken from the system-wide openssl.cnf file
# overrule the colon-separated list by using the option --tls-groups

if [ -z "$TLS_GROUPS" ]; then
    openvpn --config /etc/openvpn/CLIENTNAME.ovpn
else
    openvpn --config /etc/openvpn/CLIENTNAME.ovpn --tls-groups $TLS_GROUPS
fi

