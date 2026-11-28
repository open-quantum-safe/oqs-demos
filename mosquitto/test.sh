#!/bin/sh
set -eu

image=${1:-oqs-mosquitto}
suffix=$$
network="oqs-mosquitto-test-$suffix"
broker="oqs-mosquitto-broker-$suffix"
subscriber="oqs-mosquitto-subscriber-$suffix"
publisher="oqs-mosquitto-publisher-$suffix"

cleanup() {
    result=$?
    if [ "$result" -ne 0 ]; then
        for container in "$broker" "$subscriber" "$publisher"; do
            docker logs "$container" 2>&1 || true
        done
    fi
    docker rm -f "$publisher" "$subscriber" "$broker" >/dev/null 2>&1 || true
    docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker network create "$network" >/dev/null
docker run -d --name "$broker" --network "$network" --network-alias broker \
    -e BROKER_IP=broker -e EXAMPLE=broker-start.sh "$image" >/dev/null

ready=false
for _ in $(seq 1 30); do
    if docker logs "$broker" 2>&1 | grep -q 'Opening ipv4 listen socket on port 8883'; then
        ready=true
        break
    fi
    if [ "$(docker inspect -f '{{.State.Running}}' "$broker")" != true ]; then
        echo 'Broker exited before opening its TLS listener.' >&2
        exit 1
    fi
    sleep 1
done
[ "$ready" = true ] || { echo 'Broker did not open its TLS listener.' >&2; exit 1; }

providers=$(docker exec "$broker" openssl list -providers)
printf '%s\n' "$providers" | grep -q oqsprovider
docker exec "$broker" openssl x509 -in /test/cert/server.crt -noout -text | grep -iq mayo2

# The only offered group is frodo640aes, so a successful TLS 1.3 handshake
# proves that the OQS provider handled the key exchange.
handshake=$(docker exec "$broker" sh -c \
    'openssl s_client -connect 127.0.0.1:8883 -servername broker -tls1_3 -groups frodo640aes -CAfile /test/cert/CA.crt -cert /test/cert/server.crt -key /test/cert/server.key -verify_return_error -verify_hostname broker -brief </dev/null' 2>&1) || true
if ! printf '%s\n' "$handshake" | grep -q 'Protocol version: TLSv1.3' ||
   ! printf '%s\n' "$handshake" | grep -q 'Verification: OK'; then
    printf '%s\n' "$handshake" >&2
    echo 'Post-quantum TLS handshake failed.' >&2
    exit 1
fi

docker run -d --name "$subscriber" --network "$network" \
    -e BROKER_IP=broker -e EXAMPLE=subscriber-start.sh "$image" >/dev/null

subscribed=false
for _ in $(seq 1 30); do
    if docker logs "$broker" 2>&1 | grep -q 'Received SUBSCRIBE from Client_sub'; then
        subscribed=true
        break
    fi
    if [ "$(docker inspect -f '{{.State.Running}}' "$subscriber")" != true ]; then
        echo 'Subscriber exited before subscribing.' >&2
        exit 1
    fi
    sleep 1
done
[ "$subscribed" = true ] || { echo 'Subscriber did not subscribe.' >&2; exit 1; }

docker run --name "$publisher" --network "$network" \
    -e BROKER_IP=broker -e EXAMPLE=publisher-start.sh "$image"

subscriber_status=$(timeout 30 docker wait "$subscriber")
[ "$subscriber_status" = 0 ] || { echo "Subscriber exited with status $subscriber_status." >&2; exit 1; }
docker logs "$subscriber" 2>&1 | grep -q 'test/sensor1 Hello world\.'

echo 'Mosquitto post-quantum TLS handshake and MQTT delivery passed.'
