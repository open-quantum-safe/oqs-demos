## Warning

This integration is currently not supported due to [the end of life of oqs-openssl111](https://github.com/open-quantum-safe/openssl#warning). Feel free to vote this back into supported state by visiting [the discussion on the topic](https://github.com/orgs/open-quantum-safe/discussions/1602).

[OpenSSL](https://openssl.org/) is an open-source implementation of the TLS protocol and various cryptographic algorithms ([View the original README for the OQS-enabled fork here](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/README).)

## Purpose 

This directory contains a Dockerfile that builds [haproxy](https://www.haproxy.org) with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows haproxy to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build --build-arg SIG_ALG=<SIG> --tag oqs-haproxy-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#authentication)). An alternative, simplified build instruction is `docker build -t oqs-haproxy-img .`: This will generate the image with a default QSC algorithm (dilithium3 -- see Dockerfile to change this).
2. `docker run --detach --rm --name oqs-haproxy -p 4433:4433 oqs-haproxy-img`

This will start a docker container that has haproxy listening for TLS 1.3 connections on port 4433. Actual data will be served via a load-balanced `lighttpd` server running on ports 8181 and 8182.


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


### HAPROXY_PATH

This defines the resultant location of the haproxy installation.

By default this is '/opt/haproxy'. It is recommended to not change this. Also, all [usage documentation](USAGE.md) assumes this path.

### HAPROXY_VERSION

This defines the haproxy software version to be build into the image. By default, this is an LTS version.

The default version set is known to work OK but one could try any value available [for download](https://www.haproxy.org/#down).

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.

