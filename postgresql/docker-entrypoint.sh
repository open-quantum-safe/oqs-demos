#!/bin/bash
set -eo pipefail

# Initialize PostgreSQL data directory if it doesn't exist
if [ ! -s "${PGDATA}/PG_VERSION" ]; then
    echo "Initializing PostgreSQL database..."
    initdb --username=postgres --auth=scram-sha-256 --pwfile=<(echo "${POSTGRES_PASSWORD:-oqs-demo-password}") "${PGDATA}"

    # Configure PostgreSQL for PQC TLS
    cat >> "${PGDATA}/postgresql.conf" <<EOF

# PQC TLS Configuration
ssl = on
ssl_cert_file = '/opt/pqcerts/server.crt'
ssl_key_file = '/opt/pqcerts/server.key'
ssl_ca_file = '/opt/pqcerts/CA.crt'
listen_addresses = '*'
EOF

    # Configure client authentication - require SSL for remote connections
    # NOTE: This is a demo configuration. For production use, review and harden these settings.
    cat > "${PGDATA}/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Local connections (password not required for local socket connections in this demo)
local   all             all                                     scram-sha-256
# IPv4 remote connections (SSL required)
hostssl all             all             0.0.0.0/0               scram-sha-256
# IPv6 remote connections (SSL required)
hostssl all             all             ::/0                    scram-sha-256
EOF

    echo "PostgreSQL initialized with PQC TLS configuration."
    echo "Signature algorithm: ${SIG_ALG:-mldsa65}"
    echo "KEM groups: ${DEFAULT_GROUPS}"

    # Verify OpenSSL providers are loaded
    echo "OpenSSL version and providers:"
    openssl version
    openssl list -providers 2>/dev/null || true
fi

exec postgres -D "${PGDATA}"
