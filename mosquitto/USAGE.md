## Purpose 

This is a [mosquitto](https://mosquitto.org) docker image building on the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows mosquitto to negotiate quantum-safe keys and use quantum-safe authentication using TLS 1.3.

## Suggested use

To communicate between the server(broker) and the client(publisher and subscriber), a quantum-safe crypto client program is required.

### In a docker network

We can use docker network to do a simple test. A docker network named "mosquitto-test":

Create a docker network and specify a network segment
```
docker network create --subnet=172.18.0.0/16 mosquitto-test
```

Run a Mosquitto MQTT broker
```
docker run --network mosquitto-test --ip 172.18.0.2 -it --rm --name oqs-mosquitto-broker -e "BROKER_IP=172.18.0.2" -e "EXAMPLE=broker-start.sh" oqs-mosquitto-img
```

Then run a Mosquitto MQTT subscriber
```
docker run --network mosquitto-test --ip 172.18.0.3 -it --rm --name oqs-mosquitto-subscriber -e "BROKER_IP=172.18.0.2" -e "SUB_IP=172.18.0.3" -e "EXAMPLE=subscriber-start.sh" oqs-mosquitto-img
```

Finally run a Mosquitto MQTT publisher
```
docker run --network mosquitto-test --ip 172.18.0.4 -it --rm --name oqs-mosquitto-publisher -e "BROKER_IP=172.18.0.2" -e "PUB_IP=172.18.0.4" -e "EXAMPLE=publisher-start.sh" oqs-mosquitto-img
```

According to these steps, we can do a simple MQTT test including a broker, a subscriber, and a publisher. If you want to do more experiments, you can use other options below.

By the way, the docker image has already generated a CA certificate and a CA key at build time(default algorithm: 'dilithium5'). You can create the CA certificate and CA key yourself.

## Other usage options

### Authentication algorithm

This mosquitto image supports all quantum-safe signature algorithms [presently supported by OQS-OpenSSL](https://github.com/open-quantum-safe/openssl#authentication). If you want to control with algorithm is actually used, you can set an environment variable when running the Docker container, e.g., requesting the Falcon512 variant:

```
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "SIG_ALG=falcon512" oqs-mosquitto-img
```

### Set the TLS_DEFAULT_GROUPS

`TLS_DEFAULT_GROUPS` is an environment variable that allows selection of QSC KEMs. This supports the colon-separated list of KEM algorithms. This option only works if the SSL_CTX_set1_groups_list API call has not been used. You can see [here](https://github.com/open-quantum-safe/openssl#build-options).

### Change Mosquitto instructions or configurations

There are three shell scripts(broker-start.sh, publisher-start.sh, and subscriber-start.sh) that can be used in this directory. Use subscriber as an example:

```
docker run -it --rm --name oqs-mosquitto-demo -p 8883:8883 -e "BROKER_IP=<ip-name-of-broker-testmachine>" -e "EXAMPLE=subscriber-start.sh" oqs-mosquitto-img
```

If you want to change Mosquitto's instructions, you can modify instructions to what you want in these scripts. If you also want to change Mosquitto broker's configuration file, you can modify this to what you want in 'broker-start.sh'.

### Set the IP address of the machine

There are three environment variables(BROKER_IP, PUB_IP, and SUB_IP) that can be set when running the Docker container.

### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

