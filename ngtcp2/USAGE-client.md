## Purpose

This is a [ngtcp2](https://github.com/ngtcp2/ngtcp2) client docker image building on [quictls](https://github.com/quictls/openssl) and [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3.

## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run --network ngtcp2-test --name ngtcp2client -it openquantumsafe/ngtcp2-client sh
```

will run the container for the quantum-safe crypto (QSC) protected ngtcp2 client on the docker network called ngtcp2-test (assuming it has already been created. If not, run `docker network create ngtcp2-test
`).

### ngtcp2 client
To interact with the ngtcp2 server, run
```
qtlsclient <address> <port> [<URI>][--groups <groups>]
```

For example, `qtlsclient ngtcp2server 6000 https://ngtcp2server --groups kyber512`

By default the ngtcp2 client supports X25519, P-256, P-384 and P-521 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/oqs-provider#algorithms).


If multiple algorithms are selected, they are separated with colons.
For example, `--groups=kyber512:p256_bikel1`


For more options, run `qtlsclient --help`

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
