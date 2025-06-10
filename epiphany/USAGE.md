# OQS-epiphany

This docker image contains a version of the [GNOME Web/epiphany](https://github.com/GNOME/epiphany) web browser built to also properly execute quantum-safe crypto (QSC) TLS operations.

To this end, it contains QSC algorithms implemented by [liboqs](https://github.com/open-quantum-safe/liboqs) and made available to OpenSSL(3) via [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) developed as part of the [OpenQuantumSafe](https://openquantumsafe.org) project.

The image is based on Ubuntu and requires the host to run the Unix X-Window system. It has been tested on a Ubuntu 24.04 system. The ARM image has been tested on a Raspberry pi 5 with Raspian Bookworm 64 bit.

## Quick start

Execute this command to open the epiphany browser window on your host:

    docker run --rm -e DISPLAY=$DISPLAY --ipc=host -v /tmp/.X11-unix:/tmp/.X11-unix  openquantumsafe/epiphany

*Note*: You may need to grant permissions for Docker to access the X display. As most users run docker in root mode, you would need:

    xhost +si:localuser:root

It may require other actions in order to make it work in other environments as well as running docker in rootless mode.

## Suggested test

Go to https://test.openquantumsafe.org where all standardized and most of the quantum-safe algorithms that are still part of the NIST PQC competition are available for TLS interoperability testing.

*Note:* By default, only the algorithms "mlkem768:p384_mlkem768:x25519" are supported by the configuration built into this Docker image.

## Quantum-safe crypto server components

If you want to set up your own server running QSC algorithms, check out [OQS-httpd/Apache](https://hub.docker.com/repository/docker/openquantumsafe/httpd) or [OQS-nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx).

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
