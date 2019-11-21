This directory contains a Dockerfile that builds nginx with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows nginx to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

To get started, install Docker and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> --tag oqs-nginx-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms)).
2. `docker run --detach --rm --name oqs-nginx -p 4433:4433 oqs-nginx-img`

This will start a docker container that has nginx listening for TLS 1.3 connections on port 4433. The following command can be used to verify that the nginx so built is capable of using quantum-safe cryptography:

`docker exec oqs-nginx /opt/openssl/apps/openssl s_client -curves <KEX> -connect localhost:4433`

where `<KEX>` can be any key exchange algorithm listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms).

`nginx.conf` can be edited if a configuration other than the one used here is desired. In particular, the `ssl_ecdh_curve` directive can be used to restrict the quantum-safe key-exchange algorithms that nginx supports.
