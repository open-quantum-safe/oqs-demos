#!/bin/bash
# This shell script is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>

mkdir cert

# copy the CA key and the cert to the cert folder
cp /test/CA.key /test/CA.crt /test/cert

# generate the new subscriber CSR using pre-set CA.key & cert
openssl req -new -newkey $SIG_ALG -keyout /test/cert/subscriber.key -out /test/cert/subscriber.csr -nodes -subj "/O=test-subscriber/CN=$SUB_IP"

# generate the subscriber cert
openssl x509 -req -in /test/cert/subscriber.csr -out /test/cert/subscriber.crt -CA /test/cert/CA.crt -CAkey /test/cert/CA.key -CAcreateserial -days 365

# modify file permissions
chmod 777 cert/*
 
# execute the mosquitto MQTT subscriber
mosquitto_sub -h $BROKER_IP -t test/sensor1 -q 0 -i "Client_sub" -d -v \
--tls-version tlsv1.3 --cafile /test/cert/CA.crt \
--cert /test/cert/subscriber.crt --key /test/cert/subscriber.key
