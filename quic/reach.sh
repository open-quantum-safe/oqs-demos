#!/bin/bash

if [[ -z "${OQS_QUIC_PORT}" ]]; then
   echo "OQS_QUIC_PORT environment variable unset. Setting to 6000."
   export OQS_PORT=6000
fi

if [[ -z "${OQS_QUIC_SERVER}" ]]; then
   echo "OQS_QUIC_SERVER environment variable unset. Setting to nginx."
   export OQS_QUIC_SERVER=nginx
fi

if [[ -z "${TLS_DEFAULT_GROUPS}" ]]; then
   echo "TLS_DEFAULT_GROUPS environment variable unset: No OQS algorithms will be announced."
fi

SSL_CERT_FILE=/root/CA.crt /root/msquic/artifacts/bin/linux/x64_Debug_openssl/quicreach -server:${OQS_QUIC_SERVER} -port:${OQS_QUIC_PORT} -alpn:h3 | grep "QUIC\|reach"

