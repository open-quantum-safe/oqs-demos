## Purpose 

This directory contains a Dockerfile that builds [OpenVPN](https://openvpn.net) with the [OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider), which configures openvpn to perform quantum-safe TLS 1.3 handshakes (KEM for key establishment and X.509 certificates/keys for mutual authentication).

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build -t oqs-openvpn .` 
2. `sh ./test.sh`

This will create an image for creating configurations, keys and certificates as well as running openvpn server(s) and client(s) within a docker network performing a quantum-safe key exchange via the Kyber768 (plain and hybrid) KEM algorithm. Any of the other [supported quantum safe KEM algorithms](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be set via the parameter `--tls-groups` in the server and client startup scripts, e.g., by setting the "TLS_GROUPS" environment variable.

Please note that the test script has only been tested to operate OK on Linux.


## Usage

Complete information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for some customization of the image built:

### LIBOQS_TAG

Tag of `liboqs` release to be used. Default "main".

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used. Default "main".

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.

### KEM_ALGLIST

Defines the list of QSC KEM algorithms to be supported by default. This value is colon separated and inserted into the system-wide `openssl.cnf` configuration file defining the behaviour of the OpenSSL3 library embedded into the OpenVPN code base.

The default value is "mlkem768:p384_mlkem768". Any algorithm name(s) [supported by OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be chosen instead.
