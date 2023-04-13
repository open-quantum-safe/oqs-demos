## Purpose 
This directory contains a Dockerfile that builds the [h2load](https://nghttp2.org/documentation/h2load-howto.html) (with support for HTTP/2 and HTTP/3 load testing) using [quictls](https://github.com/quictls/openssl) and [oqs-provider](https://github.com/open-quantum-safe/oqs-provider), which allows h2load to negotiate quantum-safe keys in TLS 1.3.

## Getting started

### Building
Assuming Docker is [installed](https://docs.docker.com/install), the following command

```
docker network create h2load-test
docker build -t h2load .
docker run --name h2load --network h2load-test -it h2load
```

will run the container for the PQ-enabled h2load.

### Testing
After running the h2load container, to verify that h2load performs quantum-safe key exchange, run containers that host OQS-enabled TLS test servers using the following commands
```bash
# To run HTTP/2 server
docker run --rm --name oqs-nginx --network h2load-test openquantumsafe/nginx

# To run QUIC server
docker run --ulimit nofile=5000:5000 --rm --network h2load-test --name oqs-nginx-quic -it openquantumsafe/nginx-quic
```
Note that to force http/1, specify `--h1`

On the command prompt in the h2load docker container, run 
```bash
# Perform basic HTTP/2 load test
h2load -n 1000 -c 10 https://oqs-nginx:4433 --groups kyber512

# Perform basic HTTP/3 load test
h2load -n 1000 -c 10 https://oqs-nginx-quic:6000 --groups kyber512 --npn-list h3
```

### Usage
Documentation for using the h2load docker image is contained in the separate [USAGE.md](./USAGE.md) file.


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
