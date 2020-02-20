## Purpose 

This directory contains a Dockerfile that builds [httpd (a.k.a the Apache HTTP Server)](https://httpd.apache.org) with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows httpd to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> --tag oqs-httpd-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#authentication)). An alternative, simplified build instruction is `docker build -t oqs-httpd-img .`: This will generate the image with a default QSC algorithm (dilithium2 -- see Dockerfile to change this).
2. `docker run --detach --rm --name oqs-httpd -p 4433:4433 oqs-httpd-img`

This will start a docker container that has httpd listening for TLS 1.3 connections on port 4433. The following command can be used to verify that the httpd so built is capable of using quantum-safe cryptography:

`docker exec oqs-httpd /opt/openssl/bin/openssl s_client -curves <KEX> -connect localhost:4433`

where `<KEX>` can be any QSC key exchange algorithm listed [here](https://github.com/open-quantum-safe/openssl#key-exchange).

## Example

This sequence

```
docker build -t oqs-httpd-img .
docker run --detach --rm --name oqs-httpd -p 4433:4433 oqs-httpd-img
docker exec oqs-httpd bash -c 'echo  "GET /" | /opt/openssl/bin/openssl s_client -CAfile CA.crt -curves frodo640aes -crlf -connect localhost:4433'
```

will

- build a quantum-safe crypto (QSC)-enabled docker image of Apache httpd with a QSC root certificate embedded
- start it serving TLS 1.3 connections protected with QSC signature algorithm Dilithium2 on port 4433
- Query its default web page using the QSC KEX algorithm Frodo640AES

*Note:* Leaving away reference to the root certificate file 'CA.crt' in the command above lets the `GET` command fail as the TLS connection can not be properly verified. Leaving away the option `-crlf` will also let the GET command fail as a security extension in Apache httpd requires CRLF command termination. You can check the nginx access logs via `docker logs oqs-httpd`.

*Note 2:* Should you fail to see the actual web server contents in the `openssl s_client` output, you may want to add the option `-ign_eof` to the command to see it, i.e., `docker exec oqs-httpd bash -c 'echo  "GET /" | /opt/openssl/bin/openssl s_client -CAfile CA.crt -curves frodo640aes -crlf -connect localhost:4433 -ign_eof'`.

## Further options

`httpd.conf` and `httpd-ssl.conf` can be edited if a configuration other than the one used here is desired. In particular, the `SSLOpenConfCmd Curves` directive can be used to restrict the quantum-safe key-exchange algorithms that httpd supports. After changing the configuration, the `docker build -t oqs-httpd-img .` command has to be re-run of course.


*Final Note:* You might want to delete the named test container at the end by running `docker rm -f oqs-httpd`.

