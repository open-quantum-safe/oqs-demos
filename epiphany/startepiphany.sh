#!/bin/bash

cd /home/oqs

if [ "$#" -gt 0 ]; then
   sed -i "$ s/$/:$1/" openssl-client.cnf
fi

epiphany
