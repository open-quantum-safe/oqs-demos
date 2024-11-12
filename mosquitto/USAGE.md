This directory contains a Dockerfile that builds [Mosquitto](https://mosquitto.org) using OpenSSL v3 using the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows `Moquitto` to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

## Suggested use

To communicate between the server(broker) and the client(publisher and subscriber), a quantum-safe crypto client program is required.

### In a docker network

We can use docker network to do a simple test. A docker network named "mosquitto-test":

Create a docker network and specify a network segment
```bash
docker network create --subnet=174.18.0.0/16 mosquitto-test
```

Run a Mosquitto MQTT broker
```bash
docker run --network mosquitto-test --ip 174.18.0.2 -it --rm --name oqs-mosquitto-broker -e "BROKER_IP=174.18.0.2" -e "EXAMPLE=broker-start.sh" oqs-mosquitto
```

Then run a Mosquitto MQTT subscriber
```bash
docker run --network mosquitto-test --ip 174.18.0.3 -it --rm --name oqs-mosquitto-subscriber -e "BROKER_IP=174.18.0.2" -e "SUB_IP=174.18.0.3" -e "EXAMPLE=subscriber-start.sh" oqs-mosquitto
```

Finally run a Mosquitto MQTT publisher
```bash
docker run --network mosquitto-test --ip 174.18.0.4 -it --rm --name oqs-mosquitto-publisher -e "BROKER_IP=174.18.0.2" -e "PUB_IP=174.18.0.4" -e "EXAMPLE=publisher-start.sh" oqs-mosquitto
```

According to these steps, we can do a simple MQTT test including a broker, a subscriber, and a publisher. If you want to do more experiments, you can use other options below.

By the way, the docker image has already generated a CA certificate and a CA key at build time. You can create the CA certificate and CA key yourself.

## Other usage options

### Authentication algorithm

This mosquitto image is capable of supporting all quantum-safe signature algorithms listed [here](https://github.com/open-quantum-safe/oqs-provider#algorithms). If you want to control with algorithm is actually used, you can set an environment variable when running the Docker container, e.g., requesting the dilithium5 variant:

```bash
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "SIG_ALG=dilithium5" oqs-mosquitto
```

### Set the TLS_DEFAULT_GROUPS

`TLS_DEFAULT_GROUPS` is an environment variable that allows selection of QSC KEMs. This supports the colon-separated list of KEM algorithms. You can only select either the complete list or subset of what was defined in `KEM_ALGLIST` when the docker image was built.

### Change Mosquitto instructions or configurations

There are three shell scripts(broker-start.sh, publisher-start.sh, and subscriber-start.sh) that can be used in this directory. Use subscriber as an example:

```bash
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "EXAMPLE=subscriber-start.sh" oqs-mosquitto
```

If you want to change Mosquitto's instructions, you can modify instructions to what you want in these scripts. If you also want to change Mosquitto broker's configuration file, you can modify this to what you want in 'broker-start.sh'.

### Set the IP address of the machine

There are three environment variables(BROKER_IP, PUB_IP, and SUB_IP) that can be set when running the Docker container.

### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

