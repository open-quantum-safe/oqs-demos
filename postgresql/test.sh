#!/bin/bash
# Test script to verify PQC TLS with PostgreSQL
set -e

IMAGE_NAME="${1:-oqs-postgresql}"
CONTAINER_NAME="oqs-postgresql-test"
PG_PORT=15432

echo "=== PostgreSQL PQC TLS Test ==="
echo "Image: ${IMAGE_NAME}"
echo ""

# Clean up any previous test container
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

# Start PostgreSQL container
echo "Starting PostgreSQL with PQC TLS..."
docker run -d --rm \
    --name ${CONTAINER_NAME} \
    -p ${PG_PORT}:5432 \
    ${IMAGE_NAME}

# Wait for PostgreSQL to become ready
echo "Waiting for PostgreSQL to start..."
for i in $(seq 1 30); do
    if docker exec ${CONTAINER_NAME} pg_isready -q 2>/dev/null; then
        echo "PostgreSQL is ready."
        break
    fi
    if [ $i -eq 30 ]; then
        echo "ERROR: PostgreSQL failed to start within 30 seconds."
        docker logs ${CONTAINER_NAME}
        docker rm -f ${CONTAINER_NAME} 2>/dev/null
        exit 1
    fi
    sleep 1
done

# Verify SSL is enabled
echo ""
echo "--- Verifying SSL configuration ---"
SSL_STATUS=$(docker exec ${CONTAINER_NAME} psql -U postgres -t -A -c "SHOW ssl;" 2>/dev/null)
if [ "${SSL_STATUS}" = "on" ]; then
    echo "PASS: SSL is enabled"
else
    echo "FAIL: SSL is not enabled (got: ${SSL_STATUS})"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null
    exit 1
fi

# Verify SSL connection over TCP
echo ""
echo "--- Verifying TLS connection over TCP ---"
SSL_RESULT=$(docker exec ${CONTAINER_NAME} psql -U postgres -h 127.0.0.1 "sslmode=require" -t -A \
    -c "SELECT pid, ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();" 2>/dev/null)
echo "pg_stat_ssl: ${SSL_RESULT}"
if echo "${SSL_RESULT}" | grep -q "|t|TLSv1.3|"; then
    echo "PASS: TLS 1.3 connection established"
else
    echo "FAIL: TLS 1.3 connection not established"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null
    exit 1
fi

# Show OpenSSL version and provider information
echo ""
echo "--- OpenSSL information ---"
docker exec ${CONTAINER_NAME} openssl version
docker exec ${CONTAINER_NAME} openssl list -providers 2>/dev/null || true

# Verify PQC certificate is in use
echo ""
echo "--- Server certificate details ---"
CERT_INFO=$(docker exec ${CONTAINER_NAME} openssl x509 -in /opt/pqcerts/server.crt -noout -text 2>/dev/null)
echo "${CERT_INFO}" | grep -E "Signature Algorithm|Public Key Algorithm|Subject:|Issuer:"
if echo "${CERT_INFO}" | grep -q "mldsa65"; then
    echo "PASS: PQC signature algorithm (mldsa65) verified"
else
    echo "FAIL: PQC signature algorithm not found in certificate"
    docker rm -f ${CONTAINER_NAME} 2>/dev/null
    exit 1
fi

# Test PQC TLS handshake using openssl s_client with STARTTLS postgres
echo ""
echo "--- Testing PQC TLS handshake with openssl s_client ---"
HANDSHAKE_OUTPUT=$(docker exec ${CONTAINER_NAME} bash -c \
    "echo '' | timeout 5 openssl s_client -connect localhost:5432 -starttls postgres 2>&1" || true)

if echo "${HANDSHAKE_OUTPUT}" | grep -q "Peer signature type: mldsa65"; then
    echo "PASS: PQC peer signature verified in TLS handshake"
else
    echo "WARN: Could not verify PQC peer signature via s_client"
fi
echo "${HANDSHAKE_OUTPUT}" | grep -E "Peer signature type|Server Temp Key|Protocol|Cipher" | head -5 || true

# Clean up
echo ""
echo "Cleaning up test container..."
docker rm -f ${CONTAINER_NAME} 2>/dev/null || true

echo ""
echo "=== Test complete ==="
