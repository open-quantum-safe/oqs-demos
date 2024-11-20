## Purpose 
This directory contains Dockerfiles that build the [ngtcp2](https://github.com/ngtcp2/ngtcp2) server and client with [quictls](https://github.com/quictls/openssl) and [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows ngtcp2 to negotiate quantum-safe keys in TLS 1.3.



## Getting started

## Server
### Building
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker build -t ngtcp2-server -f Dockerfile-server .
docker network create ngtcp2-test
docker run -it --network ngtcp2-test --name ngtcp2server ngtcp2-server
```

will build and run the container for the quantum-safe crypto (QSC) protected ngtcp2 server on the Docker network called ngtcp2-test.

### Usage
Documentation for using the server docker image is contained in the separate [USAGE-server.md](./USAGE-server.md) file.

## Client
### Building
The following commands

```
docker build -t ngtcp2-client -f Dockerfile-client .
docker run --network ngtcp2-test --name ngtcp2client -it ngtcp2-client sh
```

will build and run the container for the QSC-enabled ngtcp2 client on the same network as the server.
### Usage
Documentation for using the client docker image is contained in the separate [USAGE-client.md](./USAGE-client.md) file.


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
