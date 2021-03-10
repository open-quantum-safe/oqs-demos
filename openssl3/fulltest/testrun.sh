#!/bin/bash

# Arg1 is docker image to use as client
if [ "$#" -ne 1 ]; then
    echo "Usage: ${0} <docker-image name>. Exiting."
    exit 1
fi

# prepare test
rm -rf ca assignments.json* 
mkdir ca
# pull current CA cert
cd ca
wget https://test.openquantumsafe.org/CA.crt
cd ..

# pull list of algs/ports
wget https://test.openquantumsafe.org/assignments.json

# execute test
python3 testrun.py ${1}
