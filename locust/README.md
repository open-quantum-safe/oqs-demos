## Purpose 
This directory contains a Dockerfile that builds Locust using OpenSSL v3 using the [OQS provider](https://github.com/open-quantum-safe/oqs-provider) and Python3, which allows `Locust` to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

For more information on `Locust`, see the [official Locust project](https://github.com/locustio/locust).

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install). 
2) Run `docker build -t oqs-locust:0.0.1 .` to create a post quantum-enabled Locust docker image.
3) In order to configure endpoints and their weight, modify the file [scenarios/locustfile.py](scenarios/locustfile.py), more information can be found in [USAGE.md](USAGE.md)
4) To verify all components perform quantum-safe operations, first start the container with docker compose 

```
LOGGER_LEVEL=DEBUG HOST=https://YOUR_QS_HOST:4433 docker compose  up --scale worker=8
```
4) Connect to the locust web interface at `http://localhost:8189` and start a load test.


## Notes on this Version:

In this version, we utilize the subprocess module to execute the oqs-openssl command within Locust. Ideally, the objective should be to leverage native Python libraries. However, as of now, there are no Python libraries that support quantum-safe (QS) group for TLS 1.3. Once such libraries become available, we should prioritize recompiling Python (for add the OQS-openssl version) and using the appropriate Python libraries for this functionality.

For further reference on the Locust API, please refer to the official documentation [here](https://docs.locust.io/en/stable/).

## Usage

Information how to use locust: [available in the separate file USAGE.md](USAGE.md).

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE]

