#!/bin/bash
# This shell script is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
set -euo pipefail

# generate the configuration file for mosquitto
cat > mosquitto.conf <<'EOF'
## Listeners
listener 8883
protocol mqtt

## General configuration
allow_anonymous false

## Certificate based SSL/TLS support
cafile /test/cert/CA.crt
keyfile /test/cert/server.key
certfile /test/cert/server.crt
tls_version tlsv1.3
ciphers_tls1.3 TLS_AES_128_GCM_SHA256
require_certificate true
use_identity_as_username true
EOF

mkdir -p cert

# copy the CA key and the cert to the cert folder
cp /test/CA.key /test/CA.crt /test/cert

# generate the new server CSR using pre-set CA.key & cert
if [[ "$BROKER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    server_san="IP:$BROKER_IP"
else
    server_san="DNS:$BROKER_IP"
fi
openssl req -new -newkey "$SIG_ALG" -keyout /test/cert/server.key -out /test/cert/server.csr -nodes -subj "/O=test-server/CN=$BROKER_IP" -addext "subjectAltName=$server_san"

# generate the server cert
openssl x509 -req -in /test/cert/server.csr -out /test/cert/server.crt -CA /test/cert/CA.crt -CAkey /test/cert/CA.key -CAcreateserial -days 365 -copy_extensions copy

# modify file permissions
chmod 644 cert/*.crt
chmod 600 cert/*.key

# execute the mosquitto MQTT broker
exec mosquitto -c mosquitto.conf -v
