# Manual Mosquitto demo

Build the image from the `mosquitto` directory:

```sh
docker build -t oqs-mosquitto .
```

Open three terminals. Create a Docker network, then start the broker:

```sh
docker network create oqs-mosquitto-demo
docker run --name oqs-mosquitto-broker --network oqs-mosquitto-demo --network-alias broker \
  -e BROKER_IP=broker -e EXAMPLE=broker-start.sh oqs-mosquitto
```

In the second terminal, start a subscriber:

```sh
docker run --name oqs-mosquitto-subscriber --network oqs-mosquitto-demo \
  -e BROKER_IP=broker -e EXAMPLE=subscriber-start.sh oqs-mosquitto
```

In the third terminal, publish one message:

```sh
docker run --name oqs-mosquitto-publisher --network oqs-mosquitto-demo \
  -e BROKER_IP=broker -e EXAMPLE=publisher-start.sh oqs-mosquitto
```

The subscriber should print `test/sensor1 Hello world.` and exit. The broker listens on port 8883 and requires a client certificate. Its certificate has a `broker` DNS subject alternative name, which the MQTT clients verify through the shared demo CA.

For a repeatable check of the post-quantum TLS handshake and message delivery, use `sh ./test.sh oqs-mosquitto` instead of these manual steps.

Remove the manual demo resources when finished:

```sh
docker rm -f oqs-mosquitto-publisher oqs-mosquitto-subscriber oqs-mosquitto-broker
docker network rm oqs-mosquitto-demo
```

`BROKER_IP` is the broker hostname or IP address used by the clients and in the broker certificate. If you change it, use a name that the clients can resolve or an address they can reach. `PUB_IP` and `SUB_IP` set client certificate names; they default to `publisher` and `subscriber`. `EXAMPLE` selects one of the three startup scripts.

The image includes its demo CA private key so each container can issue its own certificate. Do not use this CA for production or expose this image to an untrusted network.
