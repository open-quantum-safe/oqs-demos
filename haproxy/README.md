# HAProxy demo

This directory builds HAProxy with OpenSSL 3, [liboqs](https://github.com/open-quantum-safe/liboqs), and [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) for experimental post-quantum TLS 1.3 key exchange and authentication. It includes two local lighttpd backends to demonstrate HTTPS load balancing.

The default build uses Alpine 3.24, OpenSSL 3.6.5, liboqs 0.16.0, oqs-provider 0.12.0, and HAProxy 3.0.32. The default KEM group is `frodo640aes` and the certificate signature algorithm is `mayo2`. These exercise oqs-provider even when OpenSSL itself supplies standardized ML-KEM and ML-DSA algorithms.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build -t oqs-haproxy .`
2. `sh ./test.sh oqs-haproxy`

The test starts the image, checks that oqs-provider is loaded, and requires a TLS 1.3 handshake with only `frodo640aes` offered. It validates the server certificate and checks that an HTTP response came from a backend.

To leave the server running, use `docker run --detach --rm --name oqs-haproxy -p 4433:4433 oqs-haproxy`.

HAProxy listens for TLS 1.3 connections on port 4433 and serves content from two load-balanced `lighttpd` backends on ports 8181 and 8182.

## Usage

Complete information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:

### OPENSSL_TAG

Tag of `openssl` release to be used.

### LIBOQS_TAG

Tag of `liboqs` release to be used.

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used.

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default is `mayo2`. Choose another TLS-capable signature algorithm from the [provider algorithm list](https://github.com/open-quantum-safe/oqs-provider#algorithms) if needed.

### KEM_ALGLIST

This defines the quantum-safe key exchange mechanisms to be supported.

The default is `frodo640aes`. Set this build argument to a colon-separated list of [provider KEM groups](https://github.com/open-quantum-safe/oqs-provider#algorithms). At runtime, `KEM_ALG` can override the configured `curves` list. Set `TEST_GROUP` when running `test.sh` against an image built with a different group.

### HAPROXY_RELEASE and HAPROXY_MICRO

These select the HAProxy version, currently 3.0.32.
