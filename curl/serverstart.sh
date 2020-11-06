#!/bin/sh
set -e

# Optionally set KEM to one defined in https://github.com/open-quantum-safe/openssl#key-exchange
if [ "x$KEM_ALG" == "x" ]; then
	export KEM_ALG=kyber512
fi

# Optionally set server certificate alg to one defined in https://github.com/open-quantum-safe/openssl#authentication
# The root CA's signature alg remains as set when building the image
if [ "x$SIG_ALG" != "x" ]; then
    cd /opt/oqssa/bin
    # generate new server CSR using pre-set CA.key & cert
    openssl req -new -newkey $SIG_ALG -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" 
    # generate server cert
    openssl x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365
fi

# Start a TLS1.3 test server based on OpenSSL accepting only the specified KEM_ALG
openssl s_server -cert /opt/test/server.crt -key /opt/test/server.key -curves $KEM_ALG -www -tls1_3 -accept localhost:4433&

# Open a shell for local experimentation
sh
