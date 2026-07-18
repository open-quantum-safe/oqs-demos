## Purpose

This directory contains a Dockerfile that builds [PostgreSQL](https://www.postgresql.org/) using OpenSSL with the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows PostgreSQL to use quantum-safe authentication **and** quantum-safe key exchange in TLS 1.3 connections between clients and the database server.

### What this demo demonstrates

- **PQC authentication**: CA and server certificates signed with ML-DSA-65 (a NIST-standardized post-quantum signature algorithm), ensuring that TLS authentication is quantum-resistant.
- **PQC key exchange** (PostgreSQL 18+): The `ssl_groups` parameter introduced in PostgreSQL 18 enables PQC KEM key exchange using X25519MLKEM768 (a hybrid X25519 + ML-KEM-768 group), protecting the TLS session against harvest-now-decrypt-later attacks.

Together, this provides a fully quantum-safe TLS 1.3 connection: both the key exchange and authentication are post-quantum secure.

### PostgreSQL version notes

- **PostgreSQL 18** (default): Supports both PQC authentication and PQC KEM key exchange via `ssl_groups`.
- **PostgreSQL 17** (fallback): Supports PQC authentication only. Key exchange uses classical ECDH because PostgreSQL 17's `ssl_ecdh_curve` parameter does not support PQC KEM groups. To build with PostgreSQL 17, set `--build-arg POSTGRESQL_VERSION=17.2`.

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

Note: With OpenSSL 3.5+, NIST-standardized PQ algorithms (ML-KEM, ML-DSA) are available via the default provider — the oqs-provider is still used for non-standardized algorithms. Everything should work identically with a more current OpenSSL version.

### LIBOQS_TAG

Tag of `liboqs` release to be used. Default is `0.13.0`.

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used. Default is `0.9.0`.

### POSTGRESQL_VERSION

Version of PostgreSQL to build. Default is `18.4`. PostgreSQL 18+ is recommended as it supports PQC KEM key exchange via `ssl_groups`. PostgreSQL 17.x can be used as a fallback (PQC authentication only).

### SIG_ALG

This defines the quantum-safe cryptographic signature algorithm for the internally generated (demonstration) CA and server certificates.

The default value is `mldsa65` (ML-DSA-65, formerly Dilithium3) but can be set to any signature algorithm supported by [the oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### DEFAULT_GROUPS

This defines the set of (possibly PQ) TLS 1.3 groups supported by the server at the OpenSSL level.

The default value is `x25519:x448:prime256v1:secp384r1:mlkem512:mlkem768:mlkem1024:X25519MLKEM768:SecP256r1MLKEM768` enabling ML-KEM variants alongside classic key exchange algorithms. For the full list of supported PQ KEM algorithms see [the oqs-provider algorithm documentation](https://github.com/open-quantum-safe/oqs-provider#algorithms).

Note: On PostgreSQL 18+, the `ssl_groups` parameter in `postgresql.conf` controls the actual groups offered by the server. The entrypoint script automatically configures `ssl_groups` using the `DEFAULT_GROUPS` environment variable for PostgreSQL 18+.

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
- The TLS handshake uses post-quantum signature verification (PQC authentication)
- PQC KEM key exchange is negotiated via X25519MLKEM768 (PostgreSQL 18+)

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

This connects over TCP with SSL required (all connections require TLS in this demo).

To verify the PQC TLS handshake with `openssl s_client`:

```
docker exec -it oqs-postgresql openssl s_client -connect localhost:5432 -starttls postgres -groups X25519MLKEM768
```

You should see `Peer signature type: mldsa65` confirming post-quantum authentication. On PostgreSQL 18+, you should also see `Server Temp Key: ML-KEM-768` (or `X25519MLKEM768`) confirming post-quantum key exchange.

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
