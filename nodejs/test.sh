#! /bin/env bash
oqs_node_image=oqs-nodejs

docker run -d --rm -p 6443:8443 --name nodejs-server --entrypoint /bin/bash -v $PWD:/code $oqs_node_image -c "
/code/createcerts.sh
cp ca_cert.crt /code
node /code/testserver.js
rm /code/ca_cert.crt"

docker run --rm --entrypoint /bin/bash --name nodejs-client --network host -v $PWD:/code $oqs_node_image -c "
set -e
node /code/client.js localhost 6443 /hello mlkem768 /code/ca_cert.crt | grep World!
node /code/client.js localhost 6443 /exit mlkem768 /code/ca_cert.crt
"
