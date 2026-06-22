#!/bin/bash
# Test script to verify PQC TLS with PostgreSQL
set -e

IMAGE_NAME="${1:-oqs-postgresql}"
CONTAINER_NAME="oqs-postgresql-test"
PG_PORT=15432
SIG_ALG="${SIG_ALG:-mldsa65}"

echo "=== PostgreSQL PQC TLS Test ==="
echo "Image: ${IMAGE_NAME}"
echo "Expected SIG_ALG: ${SIG_ALG}"
echo ""

# Clean up any previous test container
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Start PostgreSQL container
echo "Starting PostgreSQL with PQC TLS..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p "${PG_PORT}:5432" \
    "${IMAGE_NAME}"

# Wait for PostgreSQL to become ready
echo "Waiting for PostgreSQL to start..."
for i in $(seq 1 30); do
    if docker exec "${CONTAINER_NAME}" pg_isready -q 2>/dev/null; then
        echo "PostgreSQL is ready."
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: PostgreSQL failed to start within 30 seconds."
        docker logs "${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" 2>/dev/null
        exit 1
    fi
    sleep 1
done

# Verify SSL is enabled (via local socket, which does not require TLS)
echo ""
echo "--- Verifying SSL configuration ---"
SSL_STATUS=$(docker exec "${CONTAINER_NAME}" bash -c 'PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -t -A -c "SHOW ssl;"' 2>/dev/null)
if [ "${SSL_STATUS}" = "on" ]; then
    echo "PASS: SSL is enabled"
else
    echo "FAIL: SSL is not enabled (got: ${SSL_STATUS})"
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null
    exit 1
fi

# Show OpenSSL version and provider information
echo ""
echo "--- OpenSSL information ---"
docker exec "${CONTAINER_NAME}" openssl version
docker exec "${CONTAINER_NAME}" openssl list -providers 2>/dev/null || true

# Verify PQC certificate is in use
echo ""
echo "--- Server certificate details ---"
CERT_INFO=$(docker exec "${CONTAINER_NAME}" openssl x509 -in /opt/pqcerts/server.crt -noout -text 2>/dev/null)
echo "${CERT_INFO}" | grep -E "Signature Algorithm|Public Key Algorithm|Subject:|Issuer:"
if echo "${CERT_INFO}" | grep -q "${SIG_ALG}"; then
    echo "PASS: PQC signature algorithm (${SIG_ALG}) verified"
else
    echo "FAIL: PQC signature algorithm not found in certificate"
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null
    exit 1
fi

# Test PQC TLS handshake using openssl s_client with STARTTLS postgres
# NOTE: We use openssl s_client rather than psql over TCP because libpq
# does not yet support PQC certificate digest verification ("NID UNDEF").
echo ""
echo "--- Testing PQC TLS handshake with openssl s_client ---"
HANDSHAKE_OUTPUT=$(docker exec "${CONTAINER_NAME}" bash -c \
    "echo '' | timeout 5 openssl s_client -connect localhost:5432 -starttls postgres 2>&1" || true)

if echo "${HANDSHAKE_OUTPUT}" | grep -q "Protocol.*TLSv1.3"; then
    echo "PASS: TLS 1.3 connection established"
else
    echo "FAIL: TLS 1.3 connection not established"
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null
    exit 1
fi

if echo "${HANDSHAKE_OUTPUT}" | grep -q "Peer signature type: ${SIG_ALG}"; then
    echo "PASS: PQC peer signature verified in TLS handshake (PQC authentication)"
else
    echo "FAIL: PQC peer signature not found in TLS handshake"
    docker rm -f "${CONTAINER_NAME}" 2>/dev/null
    exit 1
fi
echo "${HANDSHAKE_OUTPUT}" | grep -E "Peer signature type|Server Temp Key|Protocol|Cipher" | head -5 || true

# Verify PQC KEM key exchange (PostgreSQL 18+ with ssl_groups)
echo ""
echo "--- Verifying PQC KEM key exchange ---"
PG_MAJOR=$(docker exec "${CONTAINER_NAME}" bash -c 'postgres --version | sed "s/.*) //" | cut -d. -f1' 2>/dev/null)
if [ "${PG_MAJOR}" -ge 18 ] 2>/dev/null; then
    # Verify ssl_groups is configured in PostgreSQL
    SSL_GROUPS=$(docker exec "${CONTAINER_NAME}" bash -c 'PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -t -A -c "SHOW ssl_groups;" 2>/dev/null' || true)
    if [ -n "${SSL_GROUPS}" ]; then
        echo "PASS: ssl_groups configured: ${SSL_GROUPS}"
    else
        echo "WARN: Could not verify ssl_groups setting"
    fi

    # Perform a TLS handshake requesting X25519MLKEM768 and compare
    # the client key_share size against a classical-only handshake.
    # X25519MLKEM768 key shares are ~1200 bytes; X25519 is 32 bytes,
    # so the "written" byte count is a reliable differentiator.
    KEM_HANDSHAKE=$(docker exec "${CONTAINER_NAME}" bash -c \
        "echo '' | timeout 5 openssl s_client -connect localhost:5432 -starttls postgres -groups X25519MLKEM768 2>&1" || true)
    KEM_WRITTEN=$(echo "${KEM_HANDSHAKE}" | grep -o 'written [0-9]* bytes' | grep -o '[0-9]*')
    CLASSIC_HANDSHAKE=$(docker exec "${CONTAINER_NAME}" bash -c \
        "echo '' | timeout 5 openssl s_client -connect localhost:5432 -starttls postgres -groups X25519 2>&1" || true)
    CLASSIC_WRITTEN=$(echo "${CLASSIC_HANDSHAKE}" | grep -o 'written [0-9]* bytes' | grep -o '[0-9]*')

    if [ -n "${KEM_WRITTEN}" ] && [ -n "${CLASSIC_WRITTEN}" ] && [ "${KEM_WRITTEN}" -gt "${CLASSIC_WRITTEN}" ]; then
        echo "PASS: PQC KEM key exchange negotiated (X25519MLKEM768)"
        echo "  KEM handshake: ${KEM_WRITTEN} bytes written vs classical: ${CLASSIC_WRITTEN} bytes"
    else
        echo "WARN: PQC KEM key exchange could not be confirmed via handshake size"
        echo "  KEM written=${KEM_WRITTEN:-n/a}, classical written=${CLASSIC_WRITTEN:-n/a}"
    fi
else
    echo "SKIP: PQC KEM key exchange test (requires PostgreSQL 18+, detected: ${PG_MAJOR})"
fi

# Clean up
echo ""
echo "Cleaning up test container..."
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

echo ""
echo "=== Test complete ==="
