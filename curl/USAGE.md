# OQS-curl

This docker image contains a version of [curl](https://curl.haxx.se) configured to also utilize quantum-safe crypto (QSC) operations.

To this end, it contains [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) from the [OpenQuantumSafe](https://openquantumsafe.org) project together with the latest OpenSSL (v3/master) code.

As different images providing the same base functionality may be available, e.g., for debug or performance-optimized operations, the image name `openquantumsafe/curl` is consistently used in the description below. Be sure to adapt it to the image you want to use.

## Quick start

1) `docker run -it openquantumsafe/curl` starts an OQS-enabled TLS test server.
2) On the command prompt in the docker container resulting from the first comment, one can query that server by issuing the command `curl --curves kyber768 https://localhost:4433`. 

The latter command returns all TLS information documenting use of OQS-enabled TLS. The parameter to the `--curves` argument is [any Kex Exchange algorithm supported by oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms). Alternatively, the environment variable "DEFAULT_GROUPS" can be set to request a specific PQ KEM, e.g., `DEFAULT_GROUPS=p384_kyber768 curl https://localhost:4433`. The latter example of course also necessitates starting the test server with the same KEM, e.g., by running `docker run -e KEM_ALG=p384_kyber768 -it oqs-curl`.

## Retrieving data from other QSC-enabled TLS servers

Beyond interacting with the built-in test server (utilizing `openssl s_server`) the image can also be used to retrieve data from any OQS-enabled TLS (1.3) server with the command `docker run -it openquantumsafe/curl curl <OQS-server URL>`.

All standard `curl` parameters are available plus the option to explicitly request a specific OQS algorithm ("--curves") from the [supported list of KEM algorithms](https://github.com/open-quantum-safe/oqs-provider#algorithms).


## Performance testing

The docker image can also be used to execute performance tests using the different algoritms supported: 


### TLS handshake performance

Simply start 
```
docker run -it openquantumsafe/curl perftest.sh
```
to perform TLS handshakes for 200 seconds (TEST_TIME default value) using dilithium2 (SIG_ALG default value) and kyber768 (KEM_ALG default value) keys and certificates.

A 'worked example' and more general alternative form of the command is
```
docker run -e TEST_TIME=5 -e KEM_ALG=kyber768 -e SIG_ALG=dilithium3 -it openquantumsafe/curl perftest.sh
```
runs TLS handshakes for 5 seconds exercizing `dilithium3` and `kyber768`. Again, all [supported QSC algorithms](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be set here. Be sure to properly distinguish between SIGnature_ALGorithms and KEM(Key Exchange Mechanism)_ALGorithms.


### Algorithm performance

Simply start 
```
docker run -it openquantumsafe/curl openssl speed
```
to run through all crypto algorithms built into and enabled in the docker image. This includes classic as well as quantum-safe algorithms side by side.

If interested in performance of only specific algorithms, this can be done by providing parameters as usual for [openssl speed](https://www.openssl.org/docs/man1.1.1/man1/openssl-speed.html). The list of [currently supported OQS algorithms is accessible here](https://github.com/open-quantum-safe/oqs-provider#algorithms), so an example call would be `docker run -it openquantumsafe/curl openssl speed -seconds 2 kyber512`.

#### Classic algorithm names for reference

The following algorithm names may be set if one is interested in comparative performance measurements using "classic", i.e., non-quantumsafe, crypto:

- SIG_ALG: ed25519 ed448

- KEM_ALG: X25519 P-384 P-256 P-521


