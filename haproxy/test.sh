#!/bin/sh
set -eu

image=${1:-oqs-haproxy}
group=${TEST_GROUP:-frodo640aes}
container="oqs-haproxy-test-$$"

docker run --detach --name "$container" "$image" >/dev/null
trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT

if ! providers=$(docker exec "$container" /opt/oqssa/bin/openssl list -providers 2>&1); then
    printf '%s\n' "$providers" >&2
    docker logs "$container" >&2
    exit 1
fi
if ! printf '%s\n' "$providers" | grep -q oqsprovider; then
    printf 'oqs-provider is not loaded:\n%s\n' "$providers" >&2
    exit 1
fi

attempt=0
handshake=
while [ "$attempt" -lt 5 ]; do
    attempt=$((attempt + 1))
    if handshake=$(printf 'GET / HTTP/1.1\r\nHost: oqs-haproxy\r\nConnection: close\r\n\r\n' |
        timeout 8 docker exec -i "$container" /opt/oqssa/bin/openssl s_client \
            -connect 127.0.0.1:4433 -servername oqs-haproxy \
            -tls1_3 -groups "$group" \
            -CAfile /opt/haproxy/cacert/CA.crt \
            -verify_return_error -verify_hostname oqs-haproxy -brief -ign_eof 2>&1); then
        if printf '%s\n' "$handshake" | grep -q 'Protocol version: TLSv1.3' &&
           printf '%s\n' "$handshake" | grep -q 'Hello World from lighthttpd backend'; then
            printf 'Verified TLS 1.3 with only %s offered, certificate validation, and backend response.\n' "$group"
            exit 0
        fi
    fi
    sleep 1
done

printf '%s\n' "$handshake" >&2
docker logs "$container" >&2
printf 'HAProxy TLS integration test failed.\n' >&2
exit 1
