# DEPRECATED

> [!Warning]
> This integration is currently not supported due to [the end of life of oqs-openssl111](https://github.com/open-quantum-safe/openssl#warning).

## Purpose

This directory contains a Dockerfile that builds Envoy with the [OQS BoringSSL master-with-bazel branch](https://github.com/Post-Quantum-Mesh/boringssl) modified to build the liboqs library and use the most updated BoringSSL source code.

## Getting Started

### Docker Image

A pre-built [Docker image](https://hub.docker.com/layers/drouhana/envoy-oqs/envoy/images/sha256-e779ccfd8707e31fbf3f47f1f2ac99cb52ea56f6e923a87fbb12b7fa1dbca114?context=repo) has been provided for streamlined use in envoy implementations.

It can be used identically to the standard envoy images. For example, when setting a base image for a standard Envoy implementation, one may write

    FROM envoyproxy/envoy-dev:latest

To use the post-quantum image, replace with

    FROM openquantumsafe/envoy:latest

### Local Docker Build

Install [Docker](https://docs.docker.com/get-docker/) and run the following commands:

    docker build -t envoy .

### Build From Source

Full source code, instructions, and demo can be found [here](https://github.com/Post-Quantum-Mesh/envoy-oqs).

## Sample Usage

An example implementation of oqs-enabled envoy terminating a tls handshake and proxying to an http backend has been included.

## Contact

For questions or contributions to the post-quantum cloud native project:

[Github repo](https://github.com/Post-Quantum-Mesh)

danielrouhana@pm.me
