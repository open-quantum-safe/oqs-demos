This directory contains a Dockerfile that builds curl with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows curl to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t oqs-curl .` to create a post quantum-enabled OpenSSL and Curl docker image
3) To verify all components perform quantum-safe operations, first start the container with `docker run -it oqs-curl` thus starting an OQS-enabled TLS test server.
4) On the command prompt in the docker container query that server using `curl --curves kyber512 https://localhost:4433`. If all works, the last command returns all TLS information documenting use of OQS-enabled TLS. The parameter to the `--curves` argument is the KEM_ALG chosen when building the docker container ('kyber512' by default).


## More details

The Dockerfile 
- obtains all source code required for building the quantum-safe crypto (QSC) algorithms, the QSC-enabled version of OpenSSL (v.1.1.1), curl (v.7.73.0) 
- builds all libraries and applications
- creates OQS-enabled certificate files for a mini-root certificate authority (CA) 
- creates an OQS-enabled server certificate for running a `localhost` QSC-TLS server
- by default starts an openssl (s_server) based test server.

The signature algorithm for the certificates is set to `dilithium2` by default, but can be changed to any of the [supported OQS signature algorithms](https://github.com/open-quantum-safe/openssl#authentication) with the build argumemt to docker `--build-arg SIG_ALG=`*name-of-oqs-sig-algorithm*, e.g. as follows:
```
docker build -t oqs-curl --build-arg SIG_ALG=qteslapiii .
```

**Note for the interested**: The build process is two-stage with the final image only retaining all executables, libraries and include-files to utilize OQS-enabled curl and openssl.

Two further, runtime configuration option exist that can both be optionally set via docker environment variables:

1) Setting the key exchange mechanism (KEM): By setting 'KEM_ALG'
to any of the [supported KEM algorithms built into OQS-OpenSSL](https://github.com/open-quantum-safe/openssl#key-exchange) one can run TLS using a KEM other than the default algorithm 'kyber512'. Example: `docker run -e KEM_ALG=ntru_hps2048509 -it oqs-curl`. It is always necessary to also request use of this KEM algorithm by passing it to the invocation of `curl` with the `--curves` parameter, i.e. as such in the same example: `curl --curves ntru_hps2048509 https://localhost:4433`.

2) Setting the signature algorithm (SIG): By setting 'SIG_ALG' to any of the [supported OQS signature algorithms](https://github.com/open-quantum-safe/openssl#authentication) one can run TLS using a SIG other than the one set when building the image (see above). Example: `docker run -e SIG_ALG=picnicl1full -it oqs-curl`.

#### Build type argument(s)

The Dockerfile also facilitates building the underlying OQS library to different specifications (by setting the `--build-arg` variable `LIBOQS_BUILD_DEFINES` as defined [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

For example, with this build command
```
docker build --build-arg LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF" -f Dockerfile -t oqs-curl-generic .
``` 
a generic system without processor-specific runtime optimizations is built, thus ensuring execution on all computers (at the cost of maximum runtime performance).

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### OPENSSL_BUILD_DEFINES

This permits changing the build options for the underlying openssl library containing the quantum safe algorithms. 

The default setting defines a range of default algorithms suggested for key exchange. For more information see [the documentation](https://github.com/open-quantum-safe/openssl#default-algorithms-announced).

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default value is 'dilithium3' but can be set to any value documented [here](https://github.com/open-quantum-safe/openssl#authentication).


### INSTALL_PATH

This defines the resultant location of the software installatiion.

By default this is '/opt/oqssa'. It is recommended to not change this. Also, all [usage documentation](USAGE.md) assumes this path.

### CURL_VERSION

This defines the curl software version to be build into the image.

The default version set is known to work OK providing features required for selecting QSC algorithms (via the `--curves` option). Therefore changing it is *not* recommended.

### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., '-j nnn' where nnn defines the number of jobs run in parallel during build.

The default is conservative and known not to overload normal machines. If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only '-j' for maximum parallelism) speeds up building considerably.

