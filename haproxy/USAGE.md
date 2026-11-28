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

To run the published image without building it locally:

```sh
docker run --detach --rm --name oqs-haproxy -p 4433:4433 openquantumsafe/haproxy
```

If you built the image locally, replace `openquantumsafe/haproxy` with `oqs-haproxy`.

The published image is updated after changes merge into the upstream repository. The examples below assume the image contains the `frodo640aes` and `mayo2` defaults described in this directory's Dockerfile.

The image contains its own OQS-enabled OpenSSL client. Use it to inspect a handshake with the running server:

```sh
docker exec -i oqs-haproxy /opt/oqssa/bin/openssl s_client \
  -connect 127.0.0.1:4433 -servername oqs-haproxy \
  -tls1_3 -groups frodo640aes \
  -CAfile /opt/haproxy/cacert/CA.crt \
  -verify_return_error -verify_hostname oqs-haproxy -brief </dev/null
```

To retrieve the test page, send an HTTP request through that TLS connection:

```sh
printf 'GET / HTTP/1.1\r\nHost: oqs-haproxy\r\nConnection: close\r\n\r\n' | \
docker exec -i oqs-haproxy /opt/oqssa/bin/openssl s_client \
  -connect 127.0.0.1:4433 -servername oqs-haproxy \
  -tls1_3 -groups frodo640aes \
  -CAfile /opt/haproxy/cacert/CA.crt \
  -verify_return_error -verify_hostname oqs-haproxy -brief -ign_eof
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

Set `KEM_ALG` when starting a container to override the configured group list. To test an image whose default group or certificate signature differs, set `TEST_GROUP` or `TEST_SIG` when running `test.sh`.

Supported names depend on the chosen liboqs and oqs-provider versions. Check the [oqs-provider algorithm list](https://github.com/open-quantum-safe/oqs-provider#algorithms).

## Configuration and ports

- `/opt/haproxy/conf/haproxy.cfg` configures HAProxy. Its TLS listener is on port 4433.
- `/opt/haproxy/pki/server.crt` and `/opt/haproxy/pki/server.key` hold the demo server certificate and key.
- `/opt/haproxy/cacert/CA.crt` holds the demo CA certificate.
- Port 8484 exposes HAProxy's plain HTTP statistics page if published with `-p 8484:8484`.

You can mount custom configuration and certificates at those paths. The container runs as the non-root `oqs` user, so mounted files must be readable by that user. The startup script writes `certkey.pem` in `/opt/haproxy`, which must remain writable by `oqs`.

## Generate and mount your own demo certificates

The following example uses the image's OQS-enabled OpenSSL to generate a separate `mayo2` CA and a server certificate for the name `oqs-haproxy`. Run it from the `haproxy` directory. The mounted directories must be writable by UID 1000, the image's `oqs` user.

```sh
mkdir -p demo-ca server-pki server-ca

docker run --rm -v "$PWD/demo-ca:/ca" \
  --entrypoint /opt/oqssa/bin/openssl openquantumsafe/haproxy \
  req -x509 -new -newkey mayo2 -keyout /ca/CA.key -out /ca/CA.crt \
  -nodes -subj '/CN=oqstest CA' -days 365 \
  -config /opt/oqssa/ssl/openssl.cnf

docker run --rm -v "$PWD/server-pki:/pki" \
  --entrypoint /opt/oqssa/bin/openssl openquantumsafe/haproxy \
  req -new -newkey mayo2 -keyout /pki/server.key -out /pki/server.csr \
  -nodes -subj '/CN=oqs-haproxy' -addext 'subjectAltName=DNS:oqs-haproxy' \
  -config /opt/oqssa/ssl/openssl.cnf

docker run --rm -v "$PWD/demo-ca:/ca" -v "$PWD/server-pki:/pki" \
  --entrypoint /opt/oqssa/bin/openssl openquantumsafe/haproxy \
  x509 -req -in /pki/server.csr -out /pki/server.crt \
  -CA /ca/CA.crt -CAkey /ca/CA.key -CAcreateserial -days 365 \
  -copy_extensions copy

cp demo-ca/CA.crt server-ca/CA.crt

docker run --rm --name oqs-haproxy -p 4433:4433 \
  -v "$PWD/server-pki:/opt/haproxy/pki:ro" \
  -v "$PWD/server-ca:/opt/haproxy/cacert:ro" \
  openquantumsafe/haproxy
```

Keep `demo-ca/CA.key` outside the running server. This example leaves the CA key unencrypted for convenience; protect or encrypt it if you retain it. If your host user is not UID 1000, give the image's `oqs` user write access to the generation directories and read access to the mounted server key.

To customize HAProxy itself, copy the image's generated configuration, edit it, and mount the directory:

```sh
mkdir -p haproxy-conf
docker run --rm --entrypoint cat openquantumsafe/haproxy \
  /opt/haproxy/conf/haproxy.cfg > haproxy-conf/haproxy.cfg
docker run --rm --name oqs-haproxy -p 4433:4433 \
  -v "$PWD/haproxy-conf:/opt/haproxy/conf:ro" \
  -v "$PWD/server-pki:/opt/haproxy/pki:ro" \
  -v "$PWD/server-ca:/opt/haproxy/cacert:ro" \
  openquantumsafe/haproxy
```

Use a complete, valid `haproxy.cfg` in that directory. If you set `KEM_ALG` at startup, the configuration mount must be writable because the startup script edits its `curves` setting.
