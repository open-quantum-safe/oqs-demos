## Purpose 

This directory contains a Dockerfile that builds nginx with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows nginx to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> -t oqs-nginx-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#authentication)). An alternative, simplified build instruction is `docker build -t oqs-nginx-img .`: This will generate the image with a default QSC algorithm (dilithium3 -- see Dockerfile to change this).
2. `docker run --detach --rm --name oqs-nginx -p 4433:4433 oqs-nginx-img` will start up the resulting container with QSC-enabled nginx running and listening for TLS 1.3 connections on port 4433.

## Usage

Complete information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default value is 'dilithium3' but can be set to any value documented [here](https://github.com/open-quantum-safe/openssl#authentication).


### NGINX_PATH

This defines the resultant location of the nginx installatiion.

By default this is '/opt/nginx'. It is recommended to not change this. Also, all [usage documentation](USAGE.md) assumes this path.

### NGINX_VERSION

This defines the nginx software version to be build into the image.

The default version set is known to work OK but one could try any value available [for download](https://nginx.org/en/download.html).

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.
