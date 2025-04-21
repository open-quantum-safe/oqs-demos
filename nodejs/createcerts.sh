#!/bin/bash

# if env var not set, chose default certificate signature algorithm
if [ -z "$OQSSIGALG" ]; then
   OQSSIGALG="mldsa65"
fi

if [ -z "$SERVERFQDN" ]; then
    SERVERFQDN=localhost
    echo "SERVERFQDN env var not set, using localhost"
fi

# Sanity clean-up:
rm -rf server_key.key client_key.key ca_key.key ca_cert.crt client_cert.csr server_cert.csr client_cert.crt server.cert.crt

echo "Creating all certs using $OQSSIGALG..."
# generate keys
openssl genpkey -algorithm $OQSSIGALG -out server_key.key && \
openssl genpkey -algorithm $OQSSIGALG -out ca_key.key && \

# generate ca cert
# -config /usr/lib/ssl/openssl.cnf
openssl req -key ca_key.key -x509 -subj "/CN=oqsopenvpntest CA" -out ca_cert.crt && \

# generate server cert
HOSTFQDN=$SERVERFQDN openssl req -new -key server_key.key -subj "/CN=$SERVERFQDN" -out server_cert.csr && \
HOSTFQDN=$SERVERFQDN openssl x509 -req -in server_cert.csr -CA ca_cert.crt -CAkey ca_key.key -CAcreateserial  -out server_cert.crt -extensions usr_cert
