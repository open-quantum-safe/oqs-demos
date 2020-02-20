## Purpose 

This directory contains a Dockerfile that builds nginx with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows nginx to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> -t oqs-nginx-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#authentication)). An alternative, simplified build instruction is `docker build -t oqs-nginx-img .`: This will generate the image with a default QSC algorithm (dilithium2 -- see Dockerfile to change this).
2. `docker run --detach --rm --name oqs-nginx -p 4433:4433 oqs-nginx-img` will start up the resulting container with QSC-enabled nginx running and listening for TLS 1.3 connections on port 4433.

The following command can be used to verify that the nginx so built is capable of using quantum-safe cryptography:

`docker exec oqs-nginx /opt/openssl/apps/openssl s_client -CAfile CA.crt -curves <KEX> -connect localhost:4433`

where `<KEX>` can be any key exchange algorithm listed [here](https://github.com/open-quantum-safe/openssl#key-exchange).

## Examples

Running `docker exec oqs-nginx /opt/openssl/apps/openssl s_client -CAfile CA.crt -curves saber -connect localhost:4433` will use Saber to establish the test connection.

To retrieve the test page of nginx via the QSC algorithm kyber768, you can run this command `docker exec oqs-nginx bash -c 'echo "GET /" | /opt/openssl/apps/openssl s_client -CAfile CA.crt -curves kyber768 -connect localhost:4433'`. You can check the nginx access logs via `docker logs oqs-nginx`.

*Note:* Leaving away reference to the root certificate file 'CA.crt' in the command above lets the `GET` command fail as the TLS connection can not be properly verified.

*Note 2:* Should you fail to see the actual web server contents in the `openssl s_client` output, you may want to add the option `-ign_eof` to the command to see it: `docker exec oqs-nginx bash -c 'echo "GET /" | /opt/openssl/apps/openssl s_client -CAfile CA.crt -curves kyber768 -connect localhost:4433 -ign_eof'`


## Further options

`nginx.conf` can be edited if a configuration other than the one used here is desired. In particular, the `ssl_ecdh_curve` directive can be used to restrict the quantum-safe key-exchange algorithms that nginx supports. After changing the configuration, the `docker build -t oqs-nginx-img .` command has to be re-run of course.

*Final Note:* You might want to delete the named test container at the end by running `docker rm -f oqs-nginx`.
