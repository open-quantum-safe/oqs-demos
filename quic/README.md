OQS-OpenSSL-QUIC
==================================

## Warning

This integration is currently not supported due to [the end of life of oqs-openssl111](https://github.com/open-quantum-safe/openssl#warning). Feel free to vote this back into supported state by visiting [the discussion on the topic](https://github.com/orgs/open-quantum-safe/discussions/1602).

[OpenSSL](https://openssl.org/) is an open-source implementation of the TLS protocol and various cryptographic algorithms ([View the original README for the OQS-enabled fork here](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/README).)

OQS-OpenSSL\_1\_1\_1 is a fork of OpenSSL 1.1.1 that adds quantum-safe key exchange and authentication algorithms using [liboqs](https://github.com/open-quantum-safe/liboqs) for prototyping and evaluation purposes. This fork is not endorsed by the OpenSSL project.

This project adds QUIC protocol support from [quictls](https://github.com/quictls/openssl), a project by Microsoft and Akamai to add QUIC protocol support to OQS-OpenSSL.

A demo for merging OQS-OpenSSL and quictls was originally manually built and [published](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) by [Igor Barshteyn](https://www.linkedin.com/in/igorbarshteyn/).

It was then improved upon by Michael Baentsch of the Open Quantum Safe team to automate the build process (see the **merge-oqs-openssl-quic.sh** shell script in this folder) and to enable further testing of quantum-safe algorithms with the QUIC protocol, resulting in the code in this folder.

Please [see the original README](https://github.com/open-quantum-safe/openssl#readme) for OQS-OpenSSL for additional information about using and configuring OQS-OpenSSL.

Work to further experiment with the quantum-safe algorithms using the QUIC protocol is ongoing. Questions, comments, corrections, improvements, and other contributions are welcome, e.g., via issues to this project.

Thanks,

--Igor Barshteyn

## Dockerfiles

In order to simplify the experimentation with QUIC-enabled OQS-OpenSSL this folder contains all components to create a server and a client component. The server is based on a [QUIC-enabled nginx](https://hg.nginx.org/nginx-quic), the client is based on [msquic](https://github.com/microsoft/msquic/).

### Server

#### Building

In order to build the server one can simply issue the command `docker build -t oqs-quic-nginx -f Dockerfile-server .`.

#### Background

The build process first merges the two OpenSSL forks, [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl) and [quictls](https://github.com/quictls/openssl) into one OQS-QUIC-OpenSSL code repository. It then proceeds to build nginx using this OpenSSL code base incl. the base OQS library, [liboqs](https://github.com/open-quantum-safe/liboqs). In the second stage of the build process all build artifacts not required for running oqs-quic-nginx are dropped and scripts are added to permit starting an nginx server opening one port for each OQS-signature x OQS-KEM algorithm combination. Also, a default root CA and server certificates for a demo server FQDN "nginx" are created.

The server is designed to be run both in a local docker network as well as on a cloud host. Most notably, it contains all logic to create server certificates for all supported OQS signature algorithms parameterized on the fully qualified domain name (FQDN) of the host ultimately hosting the server.

#### Usage

Documentation for using the server docker image is contained in the separate [USAGE-server.md](USAGE-server.md) file.

### Client

#### Building

In order to build the client one can simply issue the command `docker build -t oqs-msquic -f Dockerfile-client .`.

#### Usage

Documentation for using the client docker image is contained in the separate [USAGE-client.md](USAGE-client.md) file.

#### Background

The build process first merges the two OpenSSL forks, [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl) and [quictls](https://github.com/quictls/openssl) into one OQS-QUIC-OpenSSL code repository. It then proceeds to build msquic using this OpenSSL code base incl. the base OQS library, [liboqs](https://github.com/open-quantum-safe/liboqs). Some patches to the `msquic` code base are applied to enable the build and experimentation with different OQS algorithms. In the second stage of the build process all build artifacts not required for running the baseline QUIC reachability test are dropped and scripts are added to permit a full test of all OQS-algorithm combinations as afforded by the server.

The client is meant for basic QUIC reachability tests by way of completing TLS handshakesn only. For further details about the client [see its documentation](https://github.com/microsoft/quicreach).

## License

All modifications to this repository are released under the same terms as OpenSSL, namely as described in the file [LICENSE](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/LICENSE).


