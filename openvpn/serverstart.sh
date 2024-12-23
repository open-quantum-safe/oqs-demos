#!/bin/bash

# Location of config files
cd /etc/openvpn

# KEMs chosen will be taken from the system-wide openssl.cnf file
# overrule the colon-separated list by using the option --tls-groups

# if env var not set, chose default certificate signature algorithm
if [ -z "$OQSIGALG" ]; then
   OQSSIGALG="mldsa65"
fi

if [ ! -f ca_cert.crt ]; then
    echo "CA file missing. Generating using $OQSSIGALG as signature algorithm..."
    createcerts_and_config.sh $OQSSIGALG
fi

if [ -z "$TLS_GROUPS" ]; then
    openvpn --config server.config 
else
    openvpn --config server.config --tls-groups $TLS_GROUPS
fi



