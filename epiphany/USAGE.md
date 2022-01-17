# OQS-epiphany

This docker image contains a version of the [epiphany](https://github.com/GNOME/epiphany) web browser built to also properly display quantum-safe crypto (QSC) TLS operations.

To this end, it contains references to algorithms supported by [liboqs](https://github.com/open-quantum-safe/liboqs) and [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl) from the [OpenQuantumSafe](https://openquantumsafe.org) project.

The image is based on Ubuntu and requires the host to run the Unix X-Window system.

This demo is based on work done by [Igor Barshteyn](https://www.linkedin.com/pulse/demonstrating-quantum-safe-tls-13-web-server-client-nist-barshteyn).

## Quick start

Execute this command to open the epiphany browser window on your host:

    docker run --net=host --privileged --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" openquantumsafe/epiphany

*Note*: You may need to grant permissions for Docker to access the X display:

    xhost +si:localuser:$USER

## Suggested test

Go to https://test.openquantumsafe.org where most quantum-safe algorithms that are still part of the NIST PQC competition are available for TLS interoperability testing.

*Note:* By default, only the algorithms "p521_kyber1024:firesaber:p384_sikep610" are supported by the configuration built into this Docker image. This list can be arbitrarly extended by passing a colon-delimited list of any of the KEM algorithms supported by [OQS-OpenSSL](https://github.com/open-quantum-safe/openssl#key-exchange):

    docker run --net=host --privileged --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" openquantumsafe/epiphany frodo640aes:sntrup761

This way, all algorithms available at their respective test ports can be trialed at https://test.openquantumsafe.org.


