[![openssl](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openssl3.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openssl3.yml)
[![QUIC](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/quic.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/quic.yml)

oqs-demos
=========

## Purpose

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.  Pre-built Docker images may also be available.

As the level of interest in providing and maintaining these integrations for public consumption has fallen, the packages are tagged with the github monikers of the persons willing to keep supporting them or the term "Unmaintained". If that tag is listed, no github support for the integration is available and the code shall be seen as a snapshot that once worked only.

We are explicitly soliciting contributors to maintain those integrations labelled "Unmaintained".

Currently available integrations at their respective support level:

|                   | **Build instructions**                                   | **Pre-built Docker image or binary files**                                                                                                                                                                                                  | Support |
|-------------------|----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| -------- |
| **curl**          | [Github: oqs-demos/curl](curl)                           | [Dockerhub: openquantumsafe/curl](https://hub.docker.com/repository/docker/openquantumsafe/curl), [Dockerhub: openquantumsafe/curl-quic](https://hub.docker.com/repository/docker/openquantumsafe/curl-quic)                                | [![curl](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/curl.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/curl.yml) Maintained: @baentsch, @pi-314159
| **Apache httpd**  | [Github: oqs-demos/httpd](httpd)                         | [Dockerhub: openquantumsafe/httpd](https://hub.docker.com/repository/docker/openquantumsafe/httpd)                                                                                                                                          | [![httpd](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/httpd.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/httpd.yml) Maintained: @baentsch
| **nginx**         | [Github: oqs-demos/nginx](nginx)                         | [Dockerhub: openquantumsafe/nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx), [Dockerhub: openquantumsafe/nginx-quic](https://hub.docker.com/repository/docker/openquantumsafe/nginx-quic)                            | [![nginx](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/nginx.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/nginx.yml) Maintained: @baentsch, @bhess, @pi-314159
| **Chromium**      | [Github: oqs-demos/chromium](chromium) (limited support) | -                                                                                                                                                                                                                                           | Maintained: @pi-314159
| **Locust**        | [Github: oqs-demos/locust](locust)                       | -                                                                                                                                                                                                                                           | [![locust](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/locust.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/locust.yml) Maintained: @davidgca
| **Wireshark**     | [Github: oqs-demos/wireshark](wireshark)                 | [Dockerhub: openquantumsafe/wireshark](https://hub.docker.com/repository/docker/openquantumsafe/wireshark)                                                                                                                                  | [![wireshark](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/wireshark.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/wireshark.yml) Maintained: @alraddady
| **NodeJS**     | [Github: oqs-demos/nodejs](nodejs)                 | [Dockerhub: openquantumsafe/nodejs](https://hub.docker.com/repository/docker/openquantumsafe/nodejs)                                                                                                                                  | [![nodejs](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/nodejs.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/nodejs.yml) Maintained: @davidkel
| **OpenSSH**       | [Github: oqs-demos/openssh](openssh)                     | [Dockerhub: openquantumsafe/openssh](https://hub.docker.com/repository/docker/openquantumsafe/openssh)                                                                                                                                      | [![openssh](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openssh.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openssh.yml) Unmaintained
| **OpenVPN**       | [Github: oqs-demos/openvpn](openvpn)                     | [Dockerhub: openquantumsafe/openvpn](https://hub.docker.com/repository/docker/openquantumsafe/openvpn)                                                                                                                                      | [![openvpn](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openvpn.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/openvpn.yml) Unmaintained
| **ngtcp2**        | [Github: oqs-demos/ngtcp2](ngtcp2)                       | Dockerhub: [Server: openquantumsafe/ngtcp2-server](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-server), [Client: openquantumsafe/ngtcp2-client](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-client) | [![ngtcp2](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/ngtcp2.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/ngtcp2.yml) Unmaintained
| **h2load**        | [Github: oqs-demos/h2load](h2load)                       | [ Dockerhub: openquantumsafe/h2load](https://hub.docker.com/repository/docker/openquantumsafe/h2load)                                                                                                                                       | [![h2load](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/h2load.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/h2load.yml) Unmaintained
| **HAproxy**       | [Github: oqs-demos/haproxy](haproxy)                     | [Dockerhub: openquantumsafe/haproxy](https://hub.docker.com/repository/docker/openquantumsafe/haproxy)                                                                                                                                      | [![haproxy](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/haproxy.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/haproxy.yml) Unmaintained
| **Mosquitto**     | [Github: oqs-demos/mosquitto](mosquitto)                 | [Dockerhub: openquantumsafe/mosquitto](https://hub.docker.com/repository/docker/openquantumsafe/mosquitto)                                                                                                                                  | [![mosquitto](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/mosquitto.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/mosquitto.yml) Unmaintained
| **Epiphany**      | [Github: oqs-demos/epiphany](epiphany)                   | [Dockerhub: openquantumsafe/epiphany](https://hub.docker.com/repository/docker/openquantumsafe/epiphany)                                                                                                                                    | [![epiphany](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/epiphany.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/epiphany.yml) Maintained: @davidkel

It should be possible to use the openssl (s_client) and curl clients with all algorithm combinations available at the Open Quantum Safe TLS/X.509 interoperability test server at https://test.openquantumsafe.org (set up using `oqs-provider v0.8.0` and `liboqs v0.12.0`) but no guarantees are given for software not explicitly labelled with the name of a person offering support for it. Since [OQS-BoringSSL](https://github.com/open-quantum-safe/boringssl) no longer maintains the same set of algorithms, software that depends on OQS-BoringSSL (e.g., nginx-quic and curl-quic) may not fully (inter)operate with the test server.

When updates to an integration with a Dockerfile are pushed to `main`, an updated `latest` image is pushed to DockerHub and ghcr.io with support for both x86_64 and arm64.

The build and test CI is run against the latest code in liboqs and oqs-provider weekly.

## Contributing

Contributions are gratefully welcomed. See our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

All modifications to this repository are released under the same terms as [liboqs](https://github.com/open-quantum-safe/liboqs), namely as described in the file [LICENSE](https://github.com/open-quantum-safe/liboqs/blob/main/LICENSE.txt).

## Team

## Contributors to oqs-demos include:

    Christian Paquin (Microsoft Research)
    Dimitris Sikeridis (University of New Mexico / Cisco Systems)
    Douglas Stebila (University of Waterloo)
    Goutam Tamvada (University of Waterloo)
    Michael Baentsch (baentsch.ch)
    ISE @ FHNW (Fachhochschule Nordwestschweiz)
    Anthony Hu (wolfSSL)
    Igor Barshteyn
    Chia-Chin Chung
    Keelan Cannoo (University of Mauritius / Cyberstorm.mu)
    Dindyal Jeevesh Rishi (University of Mauritius / cyberstorm.mu)
    Dan Rouhana (University of Washington)
    JT (Henan Raytonne Trading Company)
    David Gomez-Cambronero (Telefonica Innovacion digital)
    Khalid Alraddady (linkedin.com/in/alraddady)

## Acknowledgments

Most effort in this project has been provided by individual contributors working in their own time and out of personal interest to see how PQ crypto integrates into existing software stacks.

This project is part of [Open Quantum Safe](https://openquantumsafe.org/news/).

