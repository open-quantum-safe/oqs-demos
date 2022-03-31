## Purpose 

This directory contains a Dockerfile that builds [Mosquitto](https://mosquitto.org) with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows Mosquitto to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

Work to further experiment with the quantum-safe algorithms using the MQTT protocol is ongoing. Questions, comments, corrections, improvements, and other contributions are welcome, e.g., via issues to this project.

Thanks,

--Chia-Chin Chung

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following simplified commands in this directory:

1. `docker build -t oqs-mosquitto-img .` This will generate the image with a default QSC algorithm (key exchange: kyber512, authentication: dilithium2 -- see Dockerfile to change).
2. `docker run -it --rm --name oqs-mosquitto -p 8883:8883 oqs-mosquitto-img`

This will start a docker container that has mosquitto listening for TLS 1.3 connections on port 8883.

## Usage

Complete information on how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile allows for significant customization of the built image:

### SOURCE_PATH

This defines the resultant location of the OQS-OpenSSL, liboqs and Mosquitto installatiions.

By default this is '/usr/local/src'.

### OPENSSL_LIB_PATH

This defines the resultant location of the OQS-OpenSSL library installatiion.

By default this is '/usr/local/ssl'.

### KEM_ALG

This defines the quantum-safe cryptographic key exchange algorithm.

The default value is 'kyber512', but this value can be set to any value documented [here](https://github.com/open-quantum-safe/openssl#key-exchange).

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated server and client certificates.

The default value is 'dilithium2' but can be set to any value documented [here](https://github.com/open-quantum-safe/openssl#authentication).

### BROKER_IP

This defines the IP address(or Domain Name) of the Mosquitto MQTT broker.

By default this is 'localhost'.

### PUB_IP

This defines the IP address(or Domain Name) of the Mosquitto MQTT publisher.

By default this is 'localhost'.

### SUB_IP

This defines the IP address(or Domain Name) of the Mosquitto MQTT subscriber.

By default this is 'localhost'.

### EXAMPLE

This defines which shell script to use. There are three shell scripts(broker-start.sh, publisher-start.sh, and subscriber-start.sh) that can be used in this directory.

By default this is 'broker-start.sh'.

## License

All modifications to this repository are released under the same terms as OpenSSL, namely as described in the file [LICENSE](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/LICENSE).
