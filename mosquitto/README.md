# Mosquitto with post-quantum TLS

This image builds [Eclipse Mosquitto](https://mosquitto.org/) against OpenSSL 3 and [oqs-provider](https://github.com/open-quantum-safe/oqs-provider). The broker and MQTT clients use TLS 1.3 with a post-quantum key exchange and test certificates signed with a post-quantum signature. It is a reproducible demo, not a production broker image.

## Build and test

From this directory:

```sh
docker build -t oqs-mosquitto .
sh ./test.sh oqs-mosquitto
```

The test creates a temporary Docker network, starts the broker and subscriber, verifies that `oqsprovider` loads, completes a TLS 1.3 handshake offering only `frodo640aes`, checks the broker certificate, and publishes a message that the subscriber must receive. Containers and the network are removed when the test ends. Run both commands with `sudo` if your Docker installation requires it.

See [USAGE.md](USAGE.md) for a manual publish/subscribe example.

## Default versions and algorithms

| Component | Default |
| --- | --- |
| Ubuntu | 24.04 |
| OpenSSL | 3.6.5 |
| liboqs | 0.16.0 |
| oqs-provider | 0.12.0 |
| Mosquitto | 2.1.4 |
| TLS key exchange | `frodo640aes` |
| Certificate signature | `mayo2` |

The Dockerfile accepts `OPENSSL_TAG`, `LIBOQS_TAG`, `OQSPROVIDER_TAG`, `MOSQUITTO_TAG`, `KEM_ALGLIST`, `SIG_ALG`, `LIBOQS_BUILD_DEFINES`, and `MAKE_DEFINES` as build arguments. For example:

```sh
docker build --build-arg KEM_ALGLIST=frodo640aes --build-arg SIG_ALG=mayo2 -t oqs-mosquitto .
```

`KEM_ALGLIST` sets the default OpenSSL TLS groups. The test specifically requires `frodo640aes`; update it if you choose another group. `SIG_ALG` sets the algorithm used to generate the demo CA and broker/client certificates. The selected algorithms must be supported by the chosen liboqs and oqs-provider versions.

The CA private key is included in the image so the broker and client examples can issue certificates independently. It is for local demonstration only. Use your own certificate authority and key handling for real deployments.
