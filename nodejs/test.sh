#! /bin/env bash
oqs_node_image=oqs-nodejs
oqs_curl_image=oqs-curl-generic
set -e

docker run -d --rm -p 6443:8443 --name nodejs-server --entrypoint /bin/bash -v $PWD:/code $oqs_node_image -c "
/code/createcerts.sh
cp ca_cert.crt /code
node /code/testserver.js
rm /code/ca_cert.crt"

sleep 1s

# test http2 nodejs client
docker run --rm --entrypoint /bin/bash --name nodejs-client --network host -v $PWD:/code $oqs_node_image -c "
set -e
node /code/client.js localhost 6443 /hello mlkem768 /code/ca_cert.crt | grep World!
"

# test curl which only supports http1 client
docker run --rm --name curl-client --network host -v $PWD:/code $oqs_curl_image curl -v --curves mlkem768 --cacert /code/ca_cert.crt https://localhost:6443/hello > response.txt 2>&1
cat response.txt | grep "SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / mlkem768 / mldsa65"
cat response.txt | grep World!

# terminate the nodejs server
docker run --rm --entrypoint /bin/bash --name nodejs-client --network host -v $PWD:/code $oqs_node_image -c "
set -e
node /code/client.js localhost 6443 /exit mlkem768 /code/ca_cert.crt
"
