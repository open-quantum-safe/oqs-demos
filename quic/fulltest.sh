#!/bin/bash

cd /root

if [ $# -gt 0 ]; then
   export OQS_QUIC_SERVER=$1
else
   export OQS_QUIC_SERVER=nginx
fi

rm -f CA.crt assignments.json && wget ${OQS_QUIC_SERVER}:5999/CA.crt && wget ${OQS_QUIC_SERVER}:5999/assignments.json

python3 testrun.py assignments.json
