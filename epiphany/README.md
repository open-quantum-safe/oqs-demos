# DEPRECATED

> [!Warning]
> This integration is longer supported due to lack of interest and support, if you're interested in revitalizing this demo please submit a PR. A previous update attempt can be found [here](https://github.com/open-quantum-safe/oqs-demos/commit/da3d03042a0b39caf500f0ce3744145e66b09f70)

This directory contains a Dockerfile that builds the GNOME web browser epiphany such as to run TLS 1.3 using OQS-OpenSSL.

This demo is based on work done by [Igor Barshteyn](https://www.linkedin.com/pulse/demonstrating-quantum-safe-tls-13-web-server-client-nist-barshteyn).

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build -t oqs-epiphany .` to create a QSC-enabled epiphany docker image.

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:


### LIBOQS_TAG

Tag of `liboqs` release to be used. Default "main".

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used. Default "main".


