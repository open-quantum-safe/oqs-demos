## Purpose

This directory contains a Dockerfile that builds [NodeJS](https://nodejs.org) with the [OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider), which allows nodejs applications to perform quantum-safe TLS 1.3 handshakes using quantum-safe certificates.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build -t oqs-nodejs .`
2. `sh ./test.sh`

**IMPORTANT: The building of the oqs nodejs container image takes a very long time, upwards of 30 minutes depending on your machine and will use all available cores to do so**

The following output is expected which shows a successful completion
```
Hello, World!
```

This will create an image which can then run nodejs applications. The test will use this image to run 2 nodejs applications, 1 as a server and the other as a client. It will create keys and certificates for use by the server, then the client will connect to the server using the mlkem768 KEM algorithm as it will also verify the quantum-safe certificate presented by the server.

It is possible to change the KEM algorithm in the test but the server is coded to only use the default group list defined by the `KEM_ALGLIST` build argument of the docker file. You can change the signature algorithm in the `createcerts.sh` file to one of the signature algorithm name(s) [supported by OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider#algorithms)


Please note that the test script has only been tested to operate OK on Linux.


## Usage

Complete information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for some customization of the image built:

### LIBOQS_TAG

Tag of `liboqs` release to be used. Default "main".

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used. Default "main".

### KEM_ALGLIST

Defines the list of QSC KEM algorithms to be supported by default. This value is colon separated and inserted into the system-wide `openssl.cnf` configuration file defining the behaviour of the OpenSSL3 library used by the NodeJS binary.

The default value is "mlkem768:p384_mlkem768". Any algorithm name(s) [supported by OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be chosen instead.
