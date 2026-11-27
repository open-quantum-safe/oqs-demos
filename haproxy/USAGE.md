# Using the HAProxy demo

This image serves a test page through HAProxy on port 4433. Two local lighttpd servers provide the backend content. The image is for experimentation with post-quantum TLS, not production use.

## Build and verify locally

Run these commands from the `haproxy` directory:

```sh
docker build -t oqs-haproxy .
sh ./test.sh oqs-haproxy
```

The test checks that oqs-provider loads and that HAProxy completes a TLS 1.3 handshake when the client offers only `frodo640aes`. It also verifies the certificate and retrieves the backend page. A normal HTTPS request without a forced group does not prove that post-quantum key exchange was used.

## Run the server

```sh
docker run --detach --rm --name oqs-haproxy -p 4433:4433 oqs-haproxy
```

The image contains its own OQS-enabled OpenSSL client. Use it to inspect a handshake with the running server:

```sh
docker exec -i oqs-haproxy /opt/oqssa/bin/openssl s_client \
  -connect 127.0.0.1:4433 -servername oqs-haproxy \
  -tls1_3 -groups frodo640aes \
  -CAfile /opt/haproxy/cacert/CA.crt \
  -verify_return_error -verify_hostname oqs-haproxy -brief </dev/null
```

The default build uses a `mayo2` certificate and the `frodo640aes` KEM group, both supplied through oqs-provider. The CA and server certificate are generated during the image build and are intended only for this demo.

To stop the server, run `docker stop oqs-haproxy`.

## Change algorithms

Set `SIG_ALG` and `KEM_ALGLIST` when building the image. The group list is colon-separated:

```sh
docker build --build-arg SIG_ALG=mayo2 \
  --build-arg KEM_ALGLIST=frodo640aes:bikel1 \
  -t oqs-haproxy .
```

Set `KEM_ALG` when starting a container to override the configured group list. To test an image whose default group differs from `frodo640aes`, set `TEST_GROUP` when running `test.sh`.

Supported names depend on the chosen liboqs and oqs-provider versions. Check the [oqs-provider algorithm list](https://github.com/open-quantum-safe/oqs-provider#algorithms).

## Configuration and ports

- `/opt/haproxy/conf/haproxy.cfg` configures HAProxy. Its TLS listener is on port 4433.
- `/opt/haproxy/pki/server.crt` and `/opt/haproxy/pki/server.key` hold the demo server certificate and key.
- `/opt/haproxy/cacert/CA.crt` holds the demo CA certificate.
- Port 8484 exposes HAProxy's plain HTTP statistics page if published with `-p 8484:8484`.

You can mount custom configuration and certificates at those paths. The container runs as the non-root `oqs` user, so mounted files must be readable by that user. The startup script writes `certkey.pem` in `/opt/haproxy`, which must remain writable by `oqs`.
