This directory contains a Dockerfile that builds `haproxy` using OpenSSL v3 using the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows `haproxy` to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> --build-arg KEM_ALGLIST=<KEMS> --tag oqs-haproxy .` (`<SIG>` can be any of the signature authentication algorithms and `<KEMS>` can be a colon separated list of the Key exchange mechanisms listed [here](https://github.com/open-quantum-safe/oqs-provider#algorithms)). An alternative, simplified build instruction is `docker build -t oqs-haproxy .`: This will generate the image with a default QSC algorithm and KEMs (dilithium3, p384_kyber768:kyber768 -- see Dockerfile to change this).
2. `docker run --detach --rm --name oqs-haproxy -p 4433:4433 oqs-haproxy`

This will start a docker container that has haproxy listening for TLS 1.3 connections on port 4433. Actual data will be served via a load-balanced `lighttpd` server running on ports 8181 and 8182.


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

The default value is 'dilithium3' but can be set to any value documented [here](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### KEM_ALGLIST

This defines the quantum-safe key exchange mechanisms to be supported.

The default value is `p384_kyber768:kyber768` but can be set to any set of colon separated values documented [here](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### HAPROXY_RELEASE and HAPROXY_MICRO

These define the version of HAPROXY to use with the default set to 3.0 and 5 respectively to represent haproxy version 3.0.5.
