## Purpose

This is a [ngtcp2](https://github.com/ngtcp2/ngtcp2) client docker image building on [OQS-OpenSSL-QUIC](https://github.com/open-quantum-safe/oqs-demos/tree/main/quic), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3.

The client also comes with the [quicreach](https://github.com/microsoft/quicreach) tool, based on a modified version of  [msquic](https://github.com/microsoft/msquic/)  for QSC algorithms.


## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run --network ngtcp2-test -it openquantumsafe/ngtcp2-client bash
```

will run the container for the quantum-safe crypto (QSC) protected ngtcp2 client on the docker network called ngtcp2-test (assuming it has already been created. If not, run `docker network create ngtcp2-test
`).

### ngtcp2 client
To interact with the ngtcp2 server, run
```
client <address> <port>
```

For example, `client ngtcp2server 6000`

By default the ngtcp2 client supports X25519, P-256, P-384 and P-521 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/openssl/tree/OQS-OpenSSL_1_1_1-stable#key-exchange).

This is done as follows
```
client <address> <port> --groups=kyber512
```

If multiple algorithms are selected, they are separated with colons.
For example, `--groups=kyber512:p256_bikel1`


For more options, run `client --help`

### quicreach

The CA certificate should first be downloaded from the server with 
```
wget <address>/CA.crt
```

For example, `wget ngtcp2server/CA.crt`

To interact with the ngtcp2 server, run 
```
SSL_CERT_FILE=CA.crt quicreach <address> --port <port> --stats
```
For example, `SSL_CERT_FILE=CA.crt quicreach ngtcp2server --port 6000 --stats`

The environment variable SSL_CERT_FILE should point to the location of the downloaded CA.crt.
The address and port should correspond to those of the ngtcp2 server.

In order to change the list of algorithms, simply set the environment variable "TLS_DEFAULT_GROUPS" to a list of desired algorithms.

For example, 
```
SSL_CERT_FILE=CA.crt TLS_DEFAULT_GROUPS=kyber768:kyber512 quicreach <address> --port <port>
```


For more options, run `quicreach --help`

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
