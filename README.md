[![GitHub actions](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/linux.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/linux.yml)
[![QUIC](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/quic.yml/badge.svg)](https://github.com/open-quantum-safe/oqs-demos/actions/workflows/quic.yml)
[![open-quantum-safe](https://circleci.com/gh/open-quantum-safe/oqs-demos.svg?style=svg)](https://app.circleci.com/pipelines/github/open-quantum-safe/oqs-demos)

oqs-demos
=========

## Purpose

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.  Pre-built Docker images may also be available.

As the level of interest in providing and maintaining these integrations for public consumption has fallen, the packages are tagged with the github monikers of the persons willing to keep supporting them or the term "unsupported". If that tag is listed, no CI and github support for the integration is available and the code shall be seen as a snapshot that once worked only. 

We are explicitly soliciting contributors to maintain those integrations labelled "unsupported".

Currently available integrations at their respective support level:

|                   | **Build instructions**                                   | **Pre-built Docker image or binary files**                                                                                                                                                                                                  | Support? |
|-------------------|----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| -------- |
| **curl**          | [Github: oqs-demos/curl](curl)                           | [Dockerhub: openquantumsafe/curl](https://hub.docker.com/repository/docker/openquantumsafe/curl), [Dockerhub: openquantumsafe/curl-quic](https://hub.docker.com/repository/docker/openquantumsafe/curl-quic)                                | @baentsch, @pi-314159
| **Apache httpd**  | [Github: oqs-demos/httpd](httpd)                         | [Dockerhub: openquantumsafe/httpd](https://hub.docker.com/repository/docker/openquantumsafe/httpd)                                                                                                                                          | @baentsch
| **nginx**         | [Github: oqs-demos/nginx](nginx)                         | [Dockerhub: openquantumsafe/nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx), [Dockerhub: openquantumsafe/nginx-quic](https://hub.docker.com/repository/docker/openquantumsafe/nginx-quic)                            | @baentsch, @bhess, @pi-314159
| **Chromium**      | [Github: oqs-demos/chromium](chromium) (limited support) | -                                                                                                                                                                                                                                           | @pi-314159 |
| **OpenSSH**       | [Github: oqs-demos/openssh](openssh)                     | [Dockerhub: openquantumsafe/openssh](https://hub.docker.com/repository/docker/openquantumsafe/openssh)                                                                                                                                      | unsupported
| **Wireshark**     | [Github: oqs-demos/wireshark](wireshark)                 | [Dockerhub: openquantumsafe/wireshark](https://hub.docker.com/repository/docker/openquantumsafe/wireshark)                                                                                                                                  | unsupported
| **Epiphany**      | [Github: oqs-demos/epiphany](epiphany)                   | [Dockerhub: openquantumsafe/epiphany](https://hub.docker.com/repository/docker/openquantumsafe/epiphany)                                                                                                                                    | unsupported
| **OpenVPN**       | [Github: oqs-demos/openvpn](openvpn)                     | [Dockerhub: openquantumsafe/openvpn](https://hub.docker.com/repository/docker/openquantumsafe/openvpn)                                                                                                                                      | unsupported
| **ngtcp2**        | [Github: oqs-demos/ngtcp2](ngtcp2)                       | Dockerhub: [Server: openquantumsafe/ngtcp2-server](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-server), [Client: openquantumsafe/ngtcp2-client](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-client) | unsupported
| **OpenLiteSpeed** | [Github: oqs-demos/openlitespeed](openlitespeed)         | [ Dockerhub: openquantumsafe/openlitespeed](https://hub.docker.com/repository/docker/openquantumsafe/openlitespeed)                                                                                                                         | unsupported
| **h2load**        | [Github: oqs-demos/h2load](h2load)                       | [ Dockerhub: openquantumsafe/h2load](https://hub.docker.com/repository/docker/openquantumsafe/h2load)                                                                                                                                       | unsupported
| **HAproxy**       | [Github: oqs-demos/haproxy](haproxy)                     | [Dockerhub: openquantumsafe/haproxy](https://hub.docker.com/repository/docker/openquantumsafe/haproxy)                                                                                                                                      | unsupported
| **Mosquitto**     | [Github: oqs-demos/mosquitto](mosquitto)                 | [Dockerhub: openquantumsafe/mosquitto](https://hub.docker.com/repository/docker/openquantumsafe/mosquitto)                                                                                                                                  | unsupported
| **Envoy**         | [Github: oqs-demos/envoy](envoy)                         | [ Dockerhub: openquantumsafe/envoy](https://hub.docker.com/repository/docker/openquantumsafe/envoy)                                                                                                                                         | unsupported
| **Unbound**       | [Github: oqs-demos/unbound](unbound)                     | [ Dockerhub: openquantumsafe/unbound](https://hub.docker.com/repository/docker/openquantumsafe/unbound)                                                                                                                                     | unsupported
| **Locust**        | [Github: oqs-demos/locust](locust)                       | [ Dockerhub: openquantumsafe/locust](https://hub.docker.com/repository/docker/openquantumsafe/locust)                                                                                                                                       | @davidgca

It should be possible to use the openssl (s_client), curl and GNOME Web/epiphany clients with all algorithm combinations available at the Open Quantum Safe TLS/X.509 interoperability test server at https://test.openquantumsafe.org (set up using `oqs-provider v0.6.1` and `liboqs v0.10.1`) but no guarantees are given for software not explicitly labelled with the name of a person offering support for it. Since [OQS-BoringSSL](https://github.com/open-quantum-safe/boringssl) no longer maintains the same set of algorithms, software that depends on OQS-BoringSSL (e.g., nginx-quic and curl-quic) may not fully (inter)operate with the test server.

## Contributing

Contributions are gratefully welcomed. See our [Contributing Guide](https://github.com/open-quantum-safe/oqs-demos/wiki/Contributing-guide) for more details.

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

## Acknowledgments

Most effort in this project has been provided by individual contributors working in their own time and out of personal interest to see how PQ crypto integrates into existing software stacks.

This project is part of [Open Quantum Safe](https://openquantumsafe.org/news/).

