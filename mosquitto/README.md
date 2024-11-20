This directory contains a Dockerfile that builds [Mosquitto](https://mosquitto.org) using OpenSSL v3 using the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows `Moquitto` to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Background

[Eclipse Mosquitto](https://mosquitto.org) is an open source (EPL/EDL licensed) message broker that implements the MQTT protocol versions 5.0, 3.1.1 and 3.1. Mosquitto is lightweight and is suitable for use on all devices from low power single board computers to full servers.

The MQTT protocol provides a lightweight method of carrying out messaging using a publish/subscribe model. This makes it suitable for Internet of Things messaging such as with low power sensors or mobile devices such as phones, embedded computers or microcontrollers.

The following provides some introduction to Mosquitto:

- Introduction: [Beginners Guide To The MQTT Protocol](http://www.steves-internet-guide.com/mqtt/)
- Usage: [Mosquitto MQTT Broker](http://www.steves-internet-guide.com/mosquitto-broker/), [Using The Mosquitto_pub and Mosquitto_sub MQTT Client Tools- Examples](http://www.steves-internet-guide.com/mosquitto_pub-sub-clients/)
- Man pages: [Mosquitto Man Pages](https://mosquitto.org/documentation/)

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following simplified commands in this directory:

1. `docker build -t oqs-mosquitto .` This will generate the image with a default QSC algorithm (key exchange: kyber768:p384_kyber768, authentication: dilithium3 -- see Dockerfile to change).
2. `docker run -it --rm --name oqs-mosquitto -p 8883:8883 oqs-mosquitto`

This will start a docker container that has mosquitto MQTT broker listening for TLS 1.3 connections on port 8883.

## Usage

Complete information on how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile allows for significant customization of the built image:

### OPENSSL_TAG

Tag of `openssl` release to be used.

### LIBOQS_TAG

Tag of `liboqs` release to be used.

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used.

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default value is 'dilithium3' but can be set to any value documented [here](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### KEM_ALGLIST

This defines the quantum-safe key exchange mechanisms to be supported.

The default value is `p384_kyber768:kyber768` but can be set to any set of colon separated values documented [here](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### MOSQUITTO_TAG

These define the version of Mosquitto to use, currently set to v2.0.20

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
