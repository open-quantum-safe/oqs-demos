## Purpose 
This directory contains a Dockerfile that builds `Locust` using OpenSSL v3 using the [OQS provider](https://github.com/open-quantum-safe/oqs-provider) and Python3, which allows `Locust` to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install). 
2) Run `docker build -t oqs-locust:0.0.1 .` to create a post quantum-enabled Locust docker image.
3) To verify all components perform quantum-safe operations, first start the container with docker compose 

```LOGGER_LEVEL=DEBUG HOST=https://qsc-nginx.discovery.hi.inet:4433 docker compose  up --scale master=1 --scale worker=8```
4) Connect to the locust web interface at `http://localhost:8189` and start a load test.


## More details

The Dockerfile 
- Very similar to those we have for oqs-curl. 

Some environments variables you need to know
- LOGGER_LEVEL: Set the log level for the locust master and worker. Default is ERROR.
- HOST: Set the host to test. Default is https://test:4433
- WORKERS: Set the number of workers. The number of workers should be, at least, the same as the number of cores in the machine.
- MASTER: Set the number of master. Only one master is supported.
- MASTER_HTTP_PORT: Set the port for the master. Default is 8189.
- CURVE: Set the curve to use. Default is `kyber768`.

## Notes on this Version:

In this version, we utilize the subprocess module to execute the oqs-openssl command within Locust. Ideally, the objective should be to leverage native Python libraries. However, as of now, there are no Python libraries that support quantum-safe (QS) curves for TLS 1.3. Once such libraries become available, we should prioritize recompiling Python (for add the OQS-openssl version) and using the appropriate Python libraries for this functionality.

For further reference on the Locust API, please refer to the official documentation [here](https://docs.locust.io/en/stable/).

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE]
