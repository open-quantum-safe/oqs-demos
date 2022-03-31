## Purpose 

This is a [mosquitto](https://mosquitto.org) docker image building on the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows mosquitto to negotiate quantum-safe keys and use quantum-safe authentication using TLS 1.3.

## Quick start 

Assuming you already know how Mosquitto works.

Assuming Docker is [installed](https://docs.docker.com/install) the following command 

```
docker run -it --rm -p 8883:8883 openquantumsafe/oqs-mosquitto
```

will start up the QSC-enabled mosquitto running and listening for quantum-safe crypto protected TLS 1.3 connections on port 8883.

To communicate between the server(broker) and the client(publisher and subscriber), a quantum-safe crypto client program is required.

If you started the OQS-mosquitto image on a machine with a registered IP name, the required command is simply. Please note that because both sides(server and client) need to use the same port(8883), remember to run on different machines.

For simple example:

Broker(set all as default)
```
docker run -it --rm --name oqs-mosquitto-broker -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" openquantumsafe/oqs-mosquitto
```

Publisher
```
docker run -it --rm --name oqs-mosquitto-publisher -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "PUB_IP=<ip-name-of-publisher-testmachine>" -e "EXAMPLE=publisher-start.sh" openquantumsafe/oqs-mosquitto
```

Subscriber
```
docker run -it --rm --name oqs-mosquitto-subscriber -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "SUB_IP=<ip-name-of-subscriber-testmachine>" -e "EXAMPLE=subscriber-start.sh" openquantumsafe/oqs-mosquitto
```

By the way, For ease of demonstration, there is already a CA certificate and a CA key in this directory(use 'dilithium5'). You can create the CA certificate and CA key yourself.

## Other usage options

### Authentication algorithm

This mosquitto image supports all quantum-safe signature algorithms [presently supported by OQS-OpenSSL](https://github.com/open-quantum-safe/openssl#authentication). If you want to control with algorithm is actually used, you can set an environment variable when running the Docker container, e.g., requesting the Falcon512 variant:

```
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "SIG_ALG=falcon512" openquantumsafe/oqs-mosquitto
```

### Change Mosquitto instructions or configurations

There are three shell scripts(broker-start.sh, publisher-start.sh, and subscriber-start.sh) that can be used in this directory. Use subscriber as an example:

```
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "EXAMPLE=subscriber-start.sh" openquantumsafe/oqs-mosquitto
```

If you want to change Mosquitto's instructions, you can modify instructions to what you want in these scripts. If you also want to change Mosquitto broker's configuration file, you can modify this to what you want in 'broker-start.sh'.

### Set the IP address of the machine

There are three environment variables(BROKER_IP, PUB_IP, and SUB_IP) that can be set when running the Docker container.


### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).