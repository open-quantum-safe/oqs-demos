## Purpose 
This directory contains a Dockerfile that builds the [h2load](https://nghttp2.org/documentation/h2load-howto.html) using [OpenSSL v3](https://github.com/openssl/openssl) and [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows h2load to negotiate quantum-safe keys in TLS 1.3.

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
After running the h2load container, to verify that h2load performs quantum-safe key exchange, run an OQS-enabled TLS test server using the following commands
```bash
docker run --rm --name oqs-nginx --network h2load-test openquantumsafe/nginx
```
To force http/1.1 for both http and https URI, specify `--h1`

On the command prompt in the h2load docker container, run 
```bash
h2load -n 1000 -c 10 https://oqs-nginx:4433 --groups kyber512
```

### Usage
Documentation for using the h2load docker image is contained in the separate [USAGE.md](./USAGE.md) file.


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
