#!/bin/bash

# if env var not set, chose default certificate signature algorithm
if [ -z "$OQSSIGALG" ]; then
   OQSSIGALG="mldsa65"
fi

if [ -z "$SERVERFQDN" ]; then
    echo "SERVERFQDN env var not set. Exiting."
    exit 1
fi

if [ -z "$CLIENTFQDN" ]; then
    echo "CLIENTFQDN env var not set. Exiting."
    exit 1
fi

# Activate this if tunneling is not pre-enabled:
#if [ ! -c /dev/net/tun ]; then
#    mkdir -p /dev/net
#    mknod /dev/net/tun c 10 200
#    chmod 600 /dev/net/tun
#fi

# Sanity clean-up:
rm -rf server_key.key client_key.key ca_key.key ca_cert.crt client_cert.csr server_cert.csr client_cert.crt server.cert.crt 

echo "Creating all certs using $OQSSIGALG..."
# First create certs with all extensions required by OpenVPN:
openssl genpkey -algorithm $OQSSIGALG -out server_key.key && \
openssl genpkey -algorithm $OQSSIGALG -out client_key.key && \
openssl genpkey -algorithm $OQSSIGALG -out ca_key.key && \
openssl req -key ca_key.key -x509 -subj "/CN=oqsopenvpntest CA" -config /home/openvpn/openvpn-openssl.cnf -out ca_cert.crt && \
HOSTFQDN=$CLIENTFQDN openssl req -new -key client_key.key -subj "/CN=$CLIENTFQDN" -config /home/openvpn/openvpn-openssl.cnf -out client_cert.csr && \
HOSTFQDN=$CLIENTFQDN openssl x509 -req -in client_cert.csr -CA ca_cert.crt -CAkey ca_key.key -out client_cert.crt -extensions usr_cert -extfile /home/openvpn/openvpn-openssl.cnf && \
HOSTFQDN=$SERVERFQDN openssl req -new -key server_key.key -subj "/CN=$SERVERFQDN" -config /home/openvpn/openvpn-openssl.cnf -out server_cert.csr && \
HOSTFQDN=$SERVERFQDN openssl x509 -req -in server_cert.csr -CA ca_cert.crt -CAkey ca_key.key -CAcreateserial -out server_cert.crt -extensions usr_cert -extfile /home/openvpn/openvpn-openssl.cnf 

# Now bring config file from /home/openvpn properly changed to this directory
cp /home/openvpn/server.config server.config
sed -e "s/oqsopenvpnserver/$SERVERFQDN/g" /home/openvpn/client.config > client.config

