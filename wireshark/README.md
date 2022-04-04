This directory contains a Dockerfile that builds wireshark that is patched to understand the OIDs and codepoints in TLS 1.3 that are supported by OQS-OpenSSL.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t openquantumsafe/wireshark .` to create an QSC-enabled (codepoint and OID aware) wireshark docker image.

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for customization of the image built:

### WIRESHARK_VERSION

This permits changing the wireshark code base to be used. 

Tested default value is "3.4.9".

### QSC_SSL_FLAVOR

Different quantum-safe TLS implementations have different names for the same algorithms. This option permits switching between them. Permitted values are "oqs" and "wolfssl".

Default is "oqs".
