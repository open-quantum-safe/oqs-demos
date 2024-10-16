## Purpose 

This directory contains a Dockerfile that builds nginx using OpenSSL3 with the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows nginx to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3. For instructions on setting up and using nginx with HTTP/3 QUIC support, please refer to the [NGINX QUIC README](https://github.com/open-quantum-safe/oqs-demos/blob/main/nginx/README-QUIC.md).

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build -t oqs-nginx .` This will generate the image with a default QSC algorithm built-in (dilithium3 -- see Build options below to change this).
2. `docker run --detach --rm --name oqs-nginx -p 4433:4433 oqs-nginx` will start up the resulting container with QSC-enabled nginx running and listening for TLS 1.3 connections on port 4433.

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

The default value is 'dilithium3' but can be set to any signature algorithm supported by [the oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### DEFAULT_GROUPS

This defines the set of (possibly PQ) TLS 1.3 groups announced by the running server.

The default value is `x25519:x448:kyber512:p256_kyber512:kyber768:p384_kyber768:kyber1024:p521_kyber1024` enabling all Kyber variants as well as two classic EC algorithms. Be sure to disable the latter if no classic crypto should be used by this `nginx` instance. For the full list of supported PQ KEM algorithms see [the oqs-provider algorithm documentation](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### BASEDIR

This defines the resultant base location of the installatiion.

By default this is '/opt'. Changing this invalidates some paths in the [usage documentation](USAGE.md).

### INSTALLDIR

This defines the resultant location of the installatiion.

By default this is '/opt/nginx'. Changing this invalidates some paths in the [usage documentation](USAGE.md).

### NGINX_VERSION

This defines the nginx software version to be build into the image.

The default version set is known to work OK but one could try any value available [for download](https://nginx.org/en/download.html).

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.

### ALPINE_VERSION

The version of the `alpine` docker image to to be used.
