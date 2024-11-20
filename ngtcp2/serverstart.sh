#!/bin/sh
set -e

# Optionally set KEM to one defined in https://github.com/open-quantum-safe/oqs-provider#algorithms
if [ "x$KEM_ALG" == "x" ]; then
	export KEM_ALG=kyber512
fi

# Start ngtcp2 server accepting only the specified KEM_ALG
qtlsserver --groups $KEM_ALG "*" 6000 /certs/server.key /certs/server.crt
