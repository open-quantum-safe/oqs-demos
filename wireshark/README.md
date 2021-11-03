This directory contains a Dockerfile that builds wireshark that is patched to understand the OIDs and codepoints in TLS 1.3 that are supported by wolfSSL.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t wolfssl-wireshark .` to create a wolfSSL quantum-safe codepoint and OID aware wireshark docker image

