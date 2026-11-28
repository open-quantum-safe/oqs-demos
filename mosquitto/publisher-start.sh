#!/bin/bash
# This shell script is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
set -euo pipefail

mkdir -p cert

# copy the CA key and the cert to the cert folder
cp /test/CA.key /test/CA.crt /test/cert

# generate the new publisher CSR using pre-set CA.key & cert
openssl req -new -newkey "$SIG_ALG" -keyout /test/cert/publisher.key -out /test/cert/publisher.csr -nodes -subj "/O=test-publisher/CN=$PUB_IP"

# generate the publisher cert
openssl x509 -req -in /test/cert/publisher.csr -out /test/cert/publisher.crt -CA /test/cert/CA.crt -CAkey /test/cert/CA.key -CAcreateserial -days 365

# modify file permissions
chmod 644 cert/*.crt
chmod 600 cert/*.key

# execute the mosquitto MQTT publisher
exec mosquitto_pub -h "$BROKER_IP" -p 8883 -m "Hello world." -t test/sensor1 -q 0 -i "Client_pub" -d \
    --tls-version tlsv1.3 --cafile /test/cert/CA.crt \
    --cert /test/cert/publisher.crt --key /test/cert/publisher.key
