#!/bin/bash

cd /home/oqs

if [ "$#" -gt 0 ]; then
   sed -i "s/x25519/x25519:$1/g" openssl-client.cnf
fi

epiphany
