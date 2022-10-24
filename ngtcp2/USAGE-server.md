## Purpose

This is a [ngtcp2](https://github.com/ngtcp2/ngtcp2) server docker image building on [OQS-OpenSSL-QUIC](https://github.com/open-quantum-safe/oqs-demos/tree/main/quic), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3.


## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker network create ngtcp2-test
docker run --network ngtcp2-test -it openquantumsafe/ngtcp2-server bash
```

will run the container for the quantum-safe crypto (QSC) protected ngtcp2 server on the docker network called ngtcp2-test.


Note your ip address using the  `ifconfig` command.

Run `nginx` to start the nginx server which hosts the CA.crt for the client to download (needed for the quicreach tool).

Start the ngtcp2 server with 
```
server <address> <port>  CA.key CA.crt
```

Replace address with the address you noted earlier and port with an available port number of your choice.
For example `server 172.17.0.10 6000  CA.key CA.crt`

Alternatively, you can just run `server "*" 6000  CA.key CA.crt`

By default the ngtcp2 server supports X25519, P-256, P-384 and P-521 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/openssl/tree/OQS-OpenSSL_1_1_1-stable#key-exchange).

This is done as follows
```
server <address> <port> --groups=kyber512
```

If multiple algorithms are selected, they are separated with colons.
For example, `--groups=kyber512:p256_bikel1`

For more options, run `server --help`


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
