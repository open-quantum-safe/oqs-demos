This directory contains a Dockerfile that builds curl with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows curl to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t oqs-curl .` to create a post quantum-enabled OpenSSL and Curl docker image
3) To verify all components perform quantum-safe operations, first start the container with `docker run -it oqs-curl` thus starting an OQS-enabled TLS test server.
4) On the command prompt in the docker container query that server using `curl --curves kyber512 https://localhost:4433`. If all works, the last command returns all TLS information documenting use of OQS-enabled TLS. The parameter to the `--curves` argument is the KEM_ALG chosen when building the docker container ('kyber512' by default).


## More details

The Dockerfile 
- obtains all source code required for building the quantum-safe crypto (QSC) algorithms, the QSC-enabled version of OpenSSL (v.1.1.1), curl (v.7.69.1) 
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
to any of the [supported KEM algorithms built into OQS-OpenSSL](https://github.com/open-quantum-safe/openssl#key-exchange) one can run TLS using a KEM other than the default algorithm 'kyber512'. Example: `docker run -e KEM_ALG=newhope1024cca -it oqs-curl`. It is always necessary to also request use of this KEM algorithm by passing it to the invocation of `curl` with the `--curves` parameter, i.e. as such in the same example: `curl --curves newhope1024cca https://localhost:4433`.

2) Setting the signature algorithm (SIG): By setting 'SIG_ALG' to any of the [supported OQS signature algorithms](https://github.com/open-quantum-safe/openssl#authentication) one can run TLS using a SIG other than the one set when building the image (see above). Example: `docker run -e SIG_ALG=picnicl1fs -it oqs-curl`.

#### Build type argument(s)

The Dockerfile also facilitates building the underlying OQS library to different specifications (by setting the `--build-arg` variable `LIBOQS_BUILD_DEFINES` as defined [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

For example, with this build command
```
docker build --build-arg LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF" -f Dockerfile -t oqs-curl-generic .
``` 
a generic system without processor-specific runtime optimizations is built, thus ensuring execution on all computers (at the cost of maximum runtime performance).

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).
