# OQS-ossl3

This docker image contains a version of [OpenSSL3](https://github.com/openssl/openssl) built and extended with a [provider enabling quantum-safe crypto (QSC) operations](https://github.com/open-quantum-safe/oqs-provider).

To this end, it contains [liboqs](https://github.com/open-quantum-safe/liboqs) as well as [OpenSSL 3](https://github.com/openssl/openssl) and [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) from the [OpenQuantumSafe](https://openquantumsafe.org) project.

As different images providing the same base functionality may be available, e.g., for debug or performance-optimized operations, the image name `oqs-ossl3` is consistently used in the description below. Be sure to adapt it to the image you want to use.

## Quick start

1) With `docker run -it oqs-ossl3` start an OQS-enabled TLS test server.
2) On the command prompt in the docker container resulting from the first comment, one can query that server by issuing the command `openssl s_client -connect localhost --groups kyber768`.

The latter command returns all TLS information documenting use of OQS-enabled TLS. The parameter to the `--groups` argument is [any Kex Exchange algorithm supported by OQS-OpenSSL](https://github.com/open-quantum-safe/oqs-provider#kem-algorithms).

## Retrieving data from other QSC-enabled TLS servers

Beyond interacting with the built-in test server (utilizing `openssl s_server`) the image can also be used to retrieve data from any OQS-enabled TLS (1.3) server with the command `docker run -it oqs-ossl3 openssl s_client -connect <OQS-server address:port> --groups <suitable KEM>`.

## Limitations

This image is limited in functionality as per the [open issues documented for oqs-provider](https://github.com/open-quantum-safe/oqs-provider/issues). It also is [not fit for productive use](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
