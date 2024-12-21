#!/bin/bash

# KEMs chosen will be taken from the system-wide openssl.cnf file
# overrule the colon-separated list by using the option --tls-groups

# Location of config files:
cd /etc/openvpn

if [ ! -f ca_cert.crt ]; then
    echo "CA not found. Exiting."
    exit 1
fi

if [ -z "$TLS_GROUPS" ]; then
    openvpn --config client.config
else
    openvpn --config client.config --tls-groups $TLS_GROUPS
fi

