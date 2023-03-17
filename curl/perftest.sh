#!/bin/sh
set -e

# Optionally set KEM to one defined in https://github.com/open-quantum-safe/openssl#key-exchange
if [ "x$KEM_ALG" == "x" ]; then
	export KEM_ALG=kyber512
fi

# Optionally set SIG to one defined in https://github.com/open-quantum-safe/openssl#key-exchange
if [ "x$SIG_ALG" == "x" ]; then
	export SIG_ALG=dilithium2
fi

# Optionally set TEST_TIME
if [ "x$TEST_TIME" == "x" ]; then
	export TEST_TIME=100
fi

# Optionally set server certificate alg to one defined in https://github.com/open-quantum-safe/openssl#authentication
# The root CA's signature alg remains as set when building the image
if [ "x$SIG_ALG" != "x" ]; then
    cd /opt/oqssa/bin
    # generate new server CSR using pre-set CA.key & cert
    openssl req -new -newkey $SIG_ALG -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost"
    if [ $? -ne 0 ]; then
       echo "Error generating keys - aborting."
       exit 1
    fi
    # generate server cert
    openssl x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365
    if [ $? -ne 0 ]; then
       echo "Error generating cert - aborting."
       exit 1
    fi
fi

echo "Running $0 with SIG_ALG=$SIG_ALG and KEM_ALG=$KEM_ALG"
echo

# Start a TLS1.3 test server based on OpenSSL accepting only the specified KEM_ALG
openssl s_server -cert /opt/test/server.crt -key /opt/test/server.key -curves $KEM_ALG -www -tls1_3 -accept localhost:4433&

# Give server time to come up first:
sleep 1

# Run handshakes for $TEST_TIME seconds
# The env var KEM_ALG activates the required Group via the system openssl.cnf:
openssl s_time -connect :4433 -new -time $TEST_TIME -verify 1 | grep connections
