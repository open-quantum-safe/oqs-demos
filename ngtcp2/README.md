## Purpose 
This directory contains Dockerfiles that build [ngtcp2](https://github.com/ngtcp2/ngtcp2) server and client with  [OQS-OpenSSL-QUIC](https://github.com/open-quantum-safe/oqs-demos/tree/main/quic), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3. 


The client also comes with the [quicreach](https://github.com/microsoft/quicreach) tool, based on a modified version of  [msquic](https://github.com/microsoft/msquic/)  for QSC algorithms.

## Quick start

## Server
Assuming Docker is [installed](https://docs.docker.com/install) the following commands

```
docker build -t ngtcp2_server -f Dockerfile-server .
docker run -it ngtcp2_server bash
```

will build up and run the container for the QSC-enabled ngtcp2 server.

Note your ip address using the  `ifconfig` command.

Run `nginx` to start the nginx server which hosts the CA.crt for the client to download (needed for the quicreach tool).

Start the ngtcp2 server with 
```
server <address> <port>  CA.key CA.crt
```

Replace address with the address you noted earlier and port with an available port number of your choice.
For example `server 172.17.0.10 6000  CA.key CA.crt`


By default the ngtcp2 server supports X25519, P-256, P-384 and P-521 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/openssl/tree/OQS-OpenSSL_1_1_1-stable#key-exchange).

This is done as follows
```
server <address> <port> --groups=kyber512
```

If multiple algorithms are selected, they are separated with colons.
For example, `--groups=kyber512:p256_bikel1`

For more options, run `server --help`
## Client
The following commands

```
docker build -t ngtcp2_client -f Dockerfile-client .
docker run -it ngtcp2_client bash
```

will build up and run the container for the QSC-enabled ngtcp2 client.

Ensure that the server and the client run on the same network.

### ngtcp2 client
To interact with the ngtcp2 server, run
```
client <address> <port>
client 172.17.0.10 6000
```

The supported groups of the client may be specified in the same way as done for the server.

For more options, run `client --help`

### quicreach

The CA certificate should first be downloaded from the server with 
```
wget <address>/CA.crt
```

For example, `wget 172.17.0.10/CA.crt`

To interact with the ngtcp2 server, run 
```
SSL_CERT_FILE=CA.crt quicreach <address> --port <port> --stats
```

The environment variable SSL_CERT_FILE should point to the location of the downloaded CA.crt.
The address and port should correspond to those of the ngtcp2 server.

In order to change the list of algorithms, simply set the environment variable "TLS_DEFAULT_GROUPS" to a list of desired algorithms.

For example, 
```
SSL_CERT_FILE=CA.crt TLS_DEFAULT_GROUPS=kyber768:kyber512 quicreach <address> --port <port>
```


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
