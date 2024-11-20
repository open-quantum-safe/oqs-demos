#!/bin/bash

# Defaults
HELP=''
QUANTUM=''
FAIL=''

while getopts 'hfq' flag; do
    case "${flag}" in
        h) HELP=1 ;;
        f) FAIL=1 ;;
        q) QUANTUM=1 ;;
    esac
done

if [[ $HELP == 1 ]];
then
    printf "Envoy-OQS TLS Demo: \n    -h: Print help menu\n    -f: Query post-quantum server with standard curl implementation (will fail)\n    -q: Use post-quantum curl implementation\n"
    exit 1
fi

if [[ $FAIL == '' && $QUANTUM == '' ]];
then
    echo "Error, must specify pre-quantum (-f) or post-quantum (-q) query..."
    exit 1
fi

if [[ $QUANTUM == 1 ]];
then
    echo "Querying https server using post-quantum enabled curl..."
    echo
    sudo docker run --network host -it openquantumsafe/curl curl -v -k https://localhost:10000 -e SIG_ALG=dilithium3
fi

if [[ $FAIL == 1 ]];
then
    echo "Querying https server using standard curl implementation..."
    echo
    curl https://localhost:10000 -k -v
fi
