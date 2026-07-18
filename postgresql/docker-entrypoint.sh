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

    # PostgreSQL 18+ supports ssl_groups for PQC KEM key exchange
    PG_MAJOR=$(postgres --version | sed 's/.*) //' | cut -d. -f1)
    if [ "${PG_MAJOR}" -ge 18 ] 2>/dev/null; then
        echo "# PQC KEM key exchange (PostgreSQL 18+)" >> "${PGDATA}/postgresql.conf"
        echo "ssl_groups = '${DEFAULT_GROUPS}'" >> "${PGDATA}/postgresql.conf"
        echo "PostgreSQL ${PG_MAJOR} detected: ssl_groups configured for PQC KEM key exchange."
    else
        echo "PostgreSQL ${PG_MAJOR} detected: ssl_groups not available (requires PostgreSQL 18+)."
        echo "PQC authentication is active, but key exchange uses classical ECDH."
    fi

    # Configure client authentication - require SSL for all TCP connections
    cat > "${PGDATA}/pg_hba.conf" <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# Unix socket connections (cannot use SSL — inherently local and secure)
local   all             all                                     scram-sha-256
# All TCP connections require SSL (including localhost)
hostssl all             all             127.0.0.1/32            scram-sha-256
hostssl all             all             ::1/128                 scram-sha-256
hostssl all             all             0.0.0.0/0               scram-sha-256
hostssl all             all             ::/0                    scram-sha-256
EOF

    echo "PostgreSQL initialized with PQC TLS configuration."
    echo "Signature algorithm: ${SIG_ALG:-mldsa65}"
    echo "KEM groups: ${DEFAULT_GROUPS}"

    # Log OpenSSL version and provider status
    echo "OpenSSL version and providers:"
    openssl version
    openssl list -providers 2>/dev/null || true
fi

exec postgres -D "${PGDATA}"
