This directory contains a Dockerfile that builds OpenSSL3 master with the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows openssl3 to use quantum-safe key exchange in TLS 1.3.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t oqs-ossl3 .` to create a post quantum-enabled OpenSSL3 image
3) To verify all components perform quantum-safe operations, first start the container with `docker run -it oqs-ossl3` thus starting an OQS-enabled TLS test server.
4) On the command prompt in the docker container query that server using `openssl s_client -connect localhost --groups kyber768 `. If all works, the last command returns all TLS information documenting use of OQS-enabled TLS. The parameter to the `--groups` argument is the KEM_ALG chosen when building the docker container ('kyber768' by default).

*Note*: The last command creates a HTTP command window into the sample server. It can be exited either by typing CTRL-C or by issuing a valid command, e.g., `GET /`. The latter command will also return server-side information on the protocol and cryptographic methods used, e.g., the TLS 1.3 group actually used (kyber768 in this example).


## More details

The Dockerfile 
- obtains all source code required for building the quantum-safe crypto (QSC) algorithms, the QSC-provider and OpenSSL3 (master).
- builds all libraries and applications
- by default starts an openssl (s_server) based test server.

**Note for the interested**: The build process is two-stage with the final image only retaining all executables, libraries and include-files to utilize OQS-enabled openssl3.

One runtime configuration option exists that can be optionally set via docker environment variable:

Setting the key exchange mechanism (KEM): By setting 'KEM_ALG'
to any of the [supported KEM algorithms built into OQS-OpenSSL](https://github.com/open-quantum-safe/oqs-provider#kem-algorithms) one can run TLS using a KEM other than the default algorithm 'kyber768'. Example: `docker run -e KEM_ALG=mlkem768 -it oqs-ossl3`. It is always necessary to also request use of this KEM algorithm by passing it to the invocation of `openssl s_client` with the `--groups` parameter, i.e. as such in the same example: `openssl s_client -connect localhost --groups mlkem768 `.

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

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

### INSTALLDIR

This defines the resultant location of the software installatiion.

By default this is '/opt/oqssa'. It is recommended to not change this. Also, all [usage documentation](USAGE.md) assumes this path.

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.

### ALPINE_VERSION

The version of the `alpine` docker image to to be used.
