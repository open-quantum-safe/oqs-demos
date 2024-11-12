## Purpose
Extending the [the initial work by Igor Barshteyn](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) this image integrates quantum safe cryptography (QSC) into the [msquic](https://github.com/microsoft/msquic) software package to allow exercising all QSC algorithm combinations currently supported by the [OpenQuantumSafe](https://www.openquantumsafe.org) project.


## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run --network lsws-test  --name client -it openquantumsafe/msquic-reach bash
```

will run the container on the docker network called lsws-test (assuming it has already been created. If not, run `docker network create lsws-test`).


### quicreach

The CA certificate should first be downloaded from the server with 
```
wget <address>/CA.crt
```

For example, `wget lsws/CA.crt`

To interact with the openlitespeed server, run 
```
SSL_CERT_FILE=CA.crt quicreach <address> --port <port> --stats
```
For example, `SSL_CERT_FILE=CA.crt quicreach lsws --port 443 --stats`

The environment variable SSL_CERT_FILE should point to the location of the downloaded CA.crt.
The address and port should correspond to those of the openlitespeed server.

In order to change the list of algorithms, simply set the environment variable "TLS_DEFAULT_GROUPS" to a list of desired algorithms.
[See list of quantum-safe key exchange algorithms which the OpenLiteSpeed server supports here](https://github.com/open-quantum-safe/boringssl#key-exchange).

For example, 
```
SSL_CERT_FILE=CA.crt TLS_DEFAULT_GROUPS=kyber768:kyber512 quicreach <address> --port <port>
```


For more options, run `quicreach --help`

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
