This directory contains a Dockerfile that builds httpd (a.k.a the Apache HTTP Server) with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows httpd to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

To get started, install Docker and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> --tag oqs-httpd-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms)).
2. `docker run --detach --rm --name oqs-httpd -p 4433:4433 oqs-httpd-img`

This will start a docker container that has httpd listening for TLS 1.3 connections on port 4433. The following command can be used to verify that the httpd so built is capable of using quantum-safe cryptography:

`docker exec oqs-httpd /opt/openssl/bin/openssl s_client -curves <KEX> -connect localhost:4433`

where `<KEX>` can be any key exchange algorithm listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms).

`httpd.conf` and `httpd-ssl.conf` can be edited if a configuration other than the one used here is desired. In particular, the `SSLOpenConfCmd Curves` directive can be used to restrict the quantum-safe key-exchange algorithms that httpd supports.
