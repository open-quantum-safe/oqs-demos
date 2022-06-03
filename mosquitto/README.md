## Purpose 

This directory contains a Dockerfile that builds [Mosquitto](https://mosquitto.org) with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows Mosquitto to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

Work to further experiment with the quantum-safe algorithms using the MQTT protocol is ongoing. Questions, comments, corrections, improvements, and other contributions are welcome, e.g., via issues to this project.

Thanks,

--Chia-Chin Chung

NOTE: Further modifications have been made to accomodate the algorithms which
      are supported by wolfMQTT.

## Background

[Eclipse Mosquitto](https://mosquitto.org) is an open source (EPL/EDL licensed) message broker that implements the MQTT protocol versions 5.0, 3.1.1 and 3.1. Mosquitto is lightweight and is suitable for use on all devices from low power single board computers to full servers.

The MQTT protocol provides a lightweight method of carrying out messaging using a publish/subscribe model. This makes it suitable for Internet of Things messaging such as with low power sensors or mobile devices such as phones, embedded computers or microcontrollers.

The following provides some introduction to Mosquitto:

- Introduction: [Beginners Guide To The MQTT Protocol](http://www.steves-internet-guide.com/mqtt/)
- Usage: [Mosquitto MQTT Broker](http://www.steves-internet-guide.com/mosquitto-broker/), [Using The Mosquitto_pub and Mosquitto_sub MQTT Client Tools- Examples](http://www.steves-internet-guide.com/mosquitto_pub-sub-clients/)
- Man pages: [Mosquitto Man Pages](https://mosquitto.org/documentation/) 

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following simplified commands in this directory:

1. `docker build -t oqs-mosquitto-img .` This will generate the image with a default QSC algorithm (key exchange: kyber512, authentication: falcon512 -- these match what is supported by wolfMQTT.
2. `docker run -it --rm --name oqs-mosquitto -p 8883:8883 oqs-mosquitto-img`

This will start a docker container that has mosquitto MQTT broker listening for TLS 1.3 connections on port 8883.

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

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### OPENSSL_BUILD_DEFINES

This permits changing the build options for the underlying openssl library containing the quantum safe algorithms. 

The default setting defines a range of default algorithms suggested for key exchange. For more information see [the documentation](https://github.com/open-quantum-safe/openssl#default-algorithms-announced).

### KEM_ALG

This defines the quantum-safe cryptographic key exchange algorithm.

The default value is 'kyber512' which matches what is supported by wolfMQTT.

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated server and client certificates.

The default value is 'falcon512' which matches what is supported by wolfMQTT.

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
