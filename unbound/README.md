
# Unbound(DNS-over-Tls)

This section is intended to implement the post 
quantum key exchange using [openssl](https://github.com/open-quantum-safe/openssl) on a [DNS server](https://github.com/NLnetLabs/unbound). Two Dockerfile in two folder was provided to test the key exchange between a client and the dns server over a tls connection.

A first Dockerfile with unbound configure with dns-over-tls and using the key exchange of openssl post quantum variant.

A second Dockerfile with getdns with openssl post quantum variant is used to query the DNS server to test the key exchange.

## Installation
Assuming you have docker [installed](https://docs.docker.com/install) on your machine all command below will launch respective docker.

Run Unbound DNS container:
```bash
    cd unbound-docker && \
    docker network create unbound-test && \
    docker build -t unbound_docker . && \
    docker run --interactive --publish=853:853 --tty --hostname unbound --name unbound unbound_docker
```
Documentation for using the server docker image is contained in the separate [USAGE-server.md](USAGE-server.md) file.

Open another terminal in the folder to run the getdns container:
```bash
    cd getdns-docker && \
    docker build -t getdns_docker . && \
    docker run --interactive --tty --hostname getdns --name getdns getdns_docker
```
Documentation for using the client docker image is contained in the separate [USAGE-client.md](USAGE-client.md) file.
