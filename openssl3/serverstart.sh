#!/bin/sh
set -e

# Optionally set KEM to one defined in https://github.com/open-quantum-safe/oqs-provider#kem-algorithms
if [ -z $KEM_ALG ]; then
	export KEM_ALG=kyber768
fi

# Start a TLS1.3 test server based on OpenSSL accepting only the specified KEM_ALG
openssl s_server -cert /opt/test/server.crt -key /opt/test/server.key -groups $KEM_ALG -www -tls1_3 -accept localhost:4433&

echo "Test server started for KEM $KEM_ALG at port 4433"

# Open a shell for local experimentation
if command -v bash > /dev/null; then bash; else sh; fi
