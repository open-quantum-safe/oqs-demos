# Quantum-safe QUIC client 

Extending the [the initial work by Igor Barshteyn](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) this image integrates quantum safe cryptography (QSC) into the [msquic](https://github.com/microsoft/msquic) software package to allow exercising all QSC algorithm combinations currently supported by the [OpenQuantumSafe](https://www.openquantumsafe.org) project.

## Background

To limit the size of the docker image (and the amount of functionality to be tested :) this image only contains a QSC-enabled QUIC reachability test 

## Suggested use

In order to interact with the [companion QSC-QUIC nginx image](https://hub.docker.com/repository/docker/openquantumsafe/nginxquic) the client shall be started within the same docker network:

```
docker run --network oqs-quic -it openquantumsafe/msquic-reach bash
```

Within the resulting shell, various tests for QUIC functionality can be performed:

As a baseline, to ascertain proper QUIC interoperability, it is recommended to contact the [nginx QUIC test server](https://quic.nginx.org) via `quicreach -server:quic.nginx.org -alpn:h3`. This should output correct reachability (completion of TLS handshake) and some connection (quality) statistics, notably count of UDP packets sent and received as well as the amount of data transmitted.

### Test of all algorithm combinations 

The latter information also is output for each of the QSC signature and KEM algorithms when running the full matrix test via the command

```
/root/fulltest.sh [<OQS-QUIC test server FQDN>]
```

To perform this test, the image downloads from the server optionally passed as an argument ('nginx' being the default) the server's root CA certificate and list of OQS-algorithm port assignments.

Output is a CSV structure comprising QSC signature name, QSC KEM name, 0 or 1 indicating whether or not the QUIC TLS handshake was completed, and the same UDP statistics indicating "ease" of connection establishment (if successful): The fewer packets and data transmitted, the more effective for QUIC is the respective QSC algorithm's combination.

