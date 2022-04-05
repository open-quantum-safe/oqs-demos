#!/bin/bash
# This shell script is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>

# generate the configuration file for mosquitto
echo -e "
## Listeners
listener 8883
max_connections -1
max_qos 2
protocol mqtt

## General configuration
allow_anonymous false
# Comment out the following two lines if using two-way authentication
#password_file /test/passwd
#acl_file /test/acl

## Certificate based SSL/TLS support
cafile /test/cert/CA.crt
keyfile /test/cert/server.key
certfile /test/cert/server.crt
tls_version tlsv1.3
ciphers_tls1.3 TLS_AES_128_GCM_SHA256
# Comment out the following two lines if using one-way authentication
require_certificate true
## Same as above
use_identity_as_username true
" > mosquitto.conf

# generate the password file(add username and password) for the mosquitto MQTT broker
mosquitto_passwd -b -c passwd user1 1234

# generate the Access Control List
echo -e "user user1\ntopic readwrite test/sensor1" > acl

mkdir cert

# copy the CA key and the cert to the cert folder
cp /test/CA.key /test/CA.crt /test/cert

# generate the new server CSR using pre-set CA.key & cert
openssl req -new -newkey $SIG_ALG -keyout /test/cert/server.key -out /test/cert/server.csr -nodes -subj "/O=test-server/CN=$BROKER_IP"

# generate the server cert
openssl x509 -req -in /test/cert/server.csr -out /test/cert/server.crt -CA /test/cert/CA.crt -CAkey /test/cert/CA.key -CAcreateserial -days 365

# modify file permissions
chmod 777 cert/*

# execute the mosquitto MQTT broker
mosquitto -c mosquitto.conf -v
