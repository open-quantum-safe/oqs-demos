# Quantum-safe nginx QUIC server

Extending the [the initial work by Igor Barshteyn](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) this mirrors the [HTTP and TCP-based quantum-safe crypto test server](https://test.openquantumsafe.org) operating quantum-safe cryptographic (QSC) algorithms using nginx using QUIC:

When starting this image, it opens one [QUIC-based](https://en.wikipedia.org/wiki/QUIC) server port for each combination of 2 classic and 39 [quantum-safe or hybrid digital signature algorithms](https://github.com/open-quantum-safe/openssl#authentication) for each of the 84 [quantum-safe or hybrid KEM algorithms](https://github.com/open-quantum-safe/openssl#key-exchange) supported by the [OpenQuantumSafe](https://www.openquantumsafe.org) [openssl 1.1.1 fork](https://github.com/open-quantum-safe/openssl) (plus one classic KEM for completeness), i.e. currently 3485 ports.

The server exposes the root CA certificate it uses to sign all ports' certificates as well as a JSON file with the mapping between the signature+KEM algorithm accessible at each port via the URIs "CA.crt" and "assignments.json", respectively at port 5999 for download by test clients.

## Background

This work deviates in setup from [the original](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) in order to facilitate two things:

1) By supporting exactly one QSC sig+KEM pair per port, a successfully completed connection (handshake) assures that a suitable client has successfully connected exactly this algorithm combination, doing away with the need for packet inspection to ascertain the use of specific algorithms.

2) A suitable client can thus request and announce exactly one KEM algorithm via the TLS1.3 supported groups mechanism, thus doing away with the need to carry a long list of supported groups somewhat restricting the amount of scarce QUIC packet size for other TLS handshake data.

## Suggested use

Due to the need for creating (classic and quantum-safe) certificates for each port, the default server name "nginx" has been chosen and is encoded in default server certificates. In order to facilitate running this image on a host with a different fully qualified domain name (FQDN) it is possible to start the server with the environment variable `SERVER_FQDN` set. In case of such start, root CA and all server certificates are re-created to match this server FQDN.

### In a docker network

Due to the large number of ports opened the server should be started this way in a docker network named "oqs-quic":

```
   docker network create oqs-quic
   docker run --ulimit nofile=5000:5000 --rm --network oqs-quic --name nginx -it openquantumsafe/nginx
```


### Standalone start

If the server is to be started on a host with the FQDN "quictest.sample.org" and exposing all QUIC ports, it should be started like this:

```
   docker run --ulimit nofile=5000:5000 -e SERVER_FQDN=quictest.sample.org --rm --network=host -it openquantumsafe/nginx
```

As many certificates for the given SERVER_FQDN and thousands of ports are created, some time should be given to the server to become fully operational before accessing it with a client, e.g., the below:

## Accessing the server

A [companion docker image](https://hub.docker.com/repository/docker/openquantumsafe/msquic-reach) is available to exercise all these algorithms by an OQS-enabled QUIC test client based on `msquic`. 
    
