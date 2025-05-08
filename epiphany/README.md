## Purpose

This directory contains a Dockerfile that builds the GNOME web browser epiphany such as to run TLS 1.3 using OQS-OpenSSL.

## Quick start

1) Be sure to have [docker installed](https://docs.docker.com/install).
2) Run `docker build --build-arg ARCH=$(uname -m) -t oqs-epiphany .` to create a QSC-enabled epiphany docker

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for significant customization of the image built:

### LIBOQS_TAG

Tag of `liboqs` release to be used.

### OQSPROVIDER_TAG

Tag of `oqsprovider` release to be used.
