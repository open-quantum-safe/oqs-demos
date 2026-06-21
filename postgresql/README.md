## Purpose

This directory contains a Dockerfile that builds [PostgreSQL](https://www.postgresql.org/) using OpenSSL with the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows PostgreSQL to use quantum-safe authentication (PQC certificates) in TLS 1.3 connections between clients and the database server.

The demo generates CA and server certificates signed with ML-DSA-65 (a NIST-standardized post-quantum signature algorithm), ensuring that TLS authentication is quantum-resistant. The key exchange uses classical ECDH as PostgreSQL 17's `ssl_ecdh_curve` parameter does not yet support PQC KEM groups (PQC KEM support requires PostgreSQL 18+ with the `ssl_groups` parameter).

## Getting started

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. `docker build -t oqs-postgresql .` This will generate the image with a default QSC algorithm (mldsa65 -- see Build options below to change this).
2. `docker run --detach --rm --name oqs-postgresql -p 5432:5432 oqs-postgresql` will start up the resulting container with QSC-enabled PostgreSQL running and listening for TLS connections on port 5432.

## Usage

Complete information on how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:

### OPENSSL_TAG

Tag of `openssl` release to be used. Default is `openssl-3.4.0`.

To use OpenSSL 3.5+ with native PQC support, set this to e.g. `openssl-3.5.0`. The entrypoint script will automatically detect OpenSSL 3.5+ and configure `ssl_groups` in `postgresql.conf`.

### LIBOQS_TAG

Tag of `liboqs` release to be used. Default is `0.13.0`.

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used. Default is `0.9.0`.

### POSTGRESQL_VERSION

Version of PostgreSQL to build. Default is `17.2`.

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default value is `mldsa65` (ML-DSA-65, formerly Dilithium3) but can be set to any signature algorithm supported by [the oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### DEFAULT_GROUPS

This defines the set of (possibly PQ) TLS 1.3 groups supported by the server.

The default value is `x25519:x448:prime256v1:secp384r1:mlkem512:mlkem768:mlkem1024:X25519MLKEM768:SecP256r1MLKEM768` enabling ML-KEM variants alongside classic key exchange algorithms. Note: `prime256v1` must be included as PostgreSQL 17 uses it as the default `ssl_ecdh_curve` for TLS 1.2 ECDH negotiation. For the full list of supported PQ KEM algorithms see [the oqs-provider algorithm documentation](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### ALPINE_VERSION

The version of the `alpine` docker image to be used. Default is `3.21`.

## Testing

A test script is provided to verify the PQC TLS setup:

```
./test.sh
```

The test verifies that:
- PostgreSQL starts with SSL enabled
- TLS 1.3 connections over TCP are functional
- PQC certificates (mldsa65) are correctly generated and in use
- The TLS handshake uses post-quantum signature verification

## Docker Compose

A `docker-compose.yml` is provided for easy startup:

```
docker compose up -d
```

You can customize the KEM groups via environment variable:

```
DEFAULT_GROUPS=mlkem768 docker compose up -d
```

## Connecting with a PQC-enabled client

To connect with a PQC-enabled `psql` client, you can use the OQS-enabled OpenSSL build. For testing from the container itself:

```
docker exec -it oqs-postgresql psql -U postgres -h 127.0.0.1 "sslmode=require"
```

To verify the PQC TLS handshake with `openssl s_client`:

```
docker exec -it oqs-postgresql openssl s_client -connect localhost:5432 -starttls postgres
```

You should see `Peer signature type: mldsa65` confirming post-quantum authentication.

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
