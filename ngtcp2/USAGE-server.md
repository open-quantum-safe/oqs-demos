## Purpose

This is a [ngtcp2](https://github.com/ngtcp2/ngtcp2) server docker image building on [quictls](https://github.com/quictls/openssl) and [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3.


## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker network create ngtcp2-test
docker run -it --network ngtcp2-test --name ngtcp2server openquantumsafe/ngtcp2-server
```

will run the container for the quantum-safe crypto (QSC) protected ngtcp2 server on port 6000 on the docker network called ngtcp2-test.
The server will negotiate kyber512 by default.


To specify other groups, set the KEM_ALG environment variable by running the ngtcp2 server container as follows 
```
docker run -it --network ngtcp2-test --name ngtcp2server -e KEM_ALG=kyber512:p256_bikel1 openquantumsafe/ngtcp2-server
```

Alternatively, you can interact with the container using sh and start the server manually
```sh
docker run -it --network ngtcp2-test --name ngtcp2server openquantumsafe/ngtcp2-server sh

# if the container is already running, run the following command instead
docker exec -it ngtcp2server sh
```

Once inside the container, start the server using
```
qtlsserver <address> <port> <private key file> <certificate key file>  --groups=<groups>
```
For example,
```sh
qtlsserver "*" 6000  /certs/server.key /certs/server.crt --groups=kyber512
```

By default the ngtcp2 server supports X25519, P-256, P-384 and P-521 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/oqs-provider#algorithms).


If multiple algorithms are selected, they are separated with colons. For example `--groups=kyber512:p256_bikel1`

For more options, run `qtlsserver --help`


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
