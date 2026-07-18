## Purpose

This is a [PostgreSQL](https://www.postgresql.org/) docker image using OpenSSL3 and the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows PostgreSQL to negotiate quantum-safe keys and use quantum-safe authentication using TLS 1.3.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/postgresql), exchange the name of the image from 'openquantumsafe/postgresql' in the examples below suitably.

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) such as to allow installation in all types of Kubernetes clusters.

## Quick start

Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run -p 5432:5432 openquantumsafe/postgresql
```

will start up the QSC-enabled PostgreSQL running and listening for quantum-safe crypto protected TLS connections on port 5432.

To connect to the database, use a quantum-safe crypto enabled client. For the simplest test, connect from within the container:

```
docker exec -it oqs-postgresql psql -U postgres "sslmode=require"
```

## Advanced usage options

### Configuring KEM algorithms

This PostgreSQL image supports quantum-safe key exchange algorithms. With OpenSSL 3.5+, NIST-standardized algorithms (ML-KEM, ML-DSA) work via the default provider; non-standardized algorithms are available via [oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms). You can control which algorithms are available via the `DEFAULT_GROUPS` environment variable:

```
docker run -e DEFAULT_GROUPS=mlkem768 -p 5432:5432 openquantumsafe/postgresql
```

### Testing with openssl s_client

You can verify the PQC TLS handshake using `openssl s_client` with the STARTTLS PostgreSQL protocol:

```
docker exec -it oqs-postgresql openssl s_client -connect localhost:5432 -starttls postgres -groups mlkem768
```

### Custom certificates

For a real deployment, you should mount your own server key and certificate:

```
docker run -p 5432:5432 \
    -v /path/to/server.key:/opt/pqcerts/server.key \
    -v /path/to/server.crt:/opt/pqcerts/server.crt \
    -v /path/to/CA.crt:/opt/pqcerts/CA.crt \
    openquantumsafe/postgresql
```

### Persistent data

To persist database data across container restarts:

```
docker run -p 5432:5432 \
    -v pgdata:/var/lib/postgresql/data \
    openquantumsafe/postgresql
```

## Configuration details

### Port: 5432

Port at which PostgreSQL listens by default for TLS connections.

### Certificate locations

- Server key: `/opt/pqcerts/server.key`
- Server certificate: `/opt/pqcerts/server.crt`
- CA certificate: `/opt/pqcerts/CA.crt`

### PostgreSQL data directory: /var/lib/postgresql/data

### KEM algorithm list: DEFAULT_GROUPS environment variable

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
