[![open-quantum-safe](https://circleci.com/gh/open-quantum-safe/oqs-demos.svg?style=svg)](https://app.circleci.com/pipelines/github/open-quantum-safe/oqs-demos)

oqs-demos
=========

## Purpose

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.  Pre-built Docker images may also be available.

Currently supported packages:

|                  | **Build instructions**                 | **Pre-built Docker image or binary files**                                                                                   |
| ---------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **curl**         | [Github: oqs-demos/curl](curl)         | [Dockerhub: openquantumsafe/curl](https://hub.docker.com/repository/docker/openquantumsafe/curl)                             |
| **Apache httpd** | [Github: oqs-demos/httpd](httpd)       | [Dockerhub: openquantumsafe/httpd](https://hub.docker.com/repository/docker/openquantumsafe/httpd)                           |
| **nginx**        | [Github: oqs-demos/nginx](nginx)       | [Dockerhub: openquantumsafe/nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx)                           |
| **Chromium** | [Github: oqs-demos/chromium](chromium) | [Binary for Ubuntu 20](https://github.com/open-quantum-safe/oqs-demos/releases/download/0.7.2/chromium-ubuntu-0.7.2.tgz) |
| **HAproxy**      | [Github: oqs-demos/haproxy](haproxy)   | [Dockerhub: openquantumsafe/haproxy](https://hub.docker.com/repository/docker/openquantumsafe/haproxy)                       |
| **OpenSSH**      | [Github: oqs-demos/openssh](openssh)   | [Dockerhub: openquantumsafe/openssh](https://hub.docker.com/repository/docker/openquantumsafe/openssh)                       |
| **Wireshark**    | [Github: oqs-demos/wireshark](wireshark)   | [Dockerhub: openquantumsafe/wireshark](https://hub.docker.com/repository/docker/openquantumsafe/wireshark)                       |
| **Epiphany**     | [Github: oqs-demos/epiphany](epiphany)   | [Dockerhub: openquantumsafe/epiphany](https://hub.docker.com/repository/docker/openquantumsafe/epiphany)                       |
| **QUIC**         | [Github: oqs-demos/quic](quic)       | Dockerhub: [Server: openquantumsafe/nginx-quic](https://hub.docker.com/repository/docker/openquantumsafe/nginx-quic), [Client: openquantumsafe/msquic](https://hub.docker.com/repository/docker/openquantumsafe/msquic-reach)                       |
| **Mosquitto**         | [Github: oqs-demos/mosquitto](mosquitto)       | [Dockerhub: openquantumsafe/mosquitto](https://hub.docker.com/repository/docker/openquantumsafe/mosquitto)               |
| **OpenVPN**      | [Github: oqs-demos/openvpn](openvpn)   | [Dockerhub: openquantumsafe/openvpn](https://hub.docker.com/repository/docker/openquantumsafe/openvpn)                       |
| **ngtcp2**         | [Github: oqs-demos/ngtcp2](ngtcp2)       | Dockerhub: [Server: openquantumsafe/ngtcp2-server](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-server), [Client: openquantumsafe/ngtcp2-client](https://hub.docker.com/repository/docker/openquantumsafe/ngtcp2-client)                       |
| **OpenLiteSpeed**         | [Github: oqs-demos/openlitespeed](openlitespeed)       | [ Dockerhub: openquantumsafe/openlitespeed](https://hub.docker.com/repository/docker/openquantumsafe/openlitespeed)                       |
| **Unbound**         | [Github: oqs-demos/unbound](unbound)       | [ Dockerhub: openquantumsafe/unbound](https://hub.docker.com/repository/docker/openquantumsafe/unbound)                       |
| **Envoy**         | [Github: oqs-demos/envoy](unbound)       | [ Dockerhub: openquantumsafe/envoy](https://hub.docker.com/repository/docker/openquantumsafe/envoy)                       |

You can use the openssl (s_client), curl, Chromium and GNOME Web/epiphany clients with the Open Quantum Safe test server at https://test.openquantumsafe.org/.

## Contributing

Contributions are gratefully welcomed. See our [Contributing Guide](https://github.com/open-quantum-safe/oqs-demos/wiki/Contributing-guide) for more details.

## License

All modifications to this repository are released under the same terms as [liboqs](https://github.com/open-quantum-safe/liboqs), namely as described in the file [LICENSE](https://github.com/open-quantum-safe/liboqs/blob/main/LICENSE.txt).

## Team

The Open Quantum Safe project is led by [Douglas Stebila](https://www.douglas.stebila.ca/research/) and [Michele Mosca](http://faculty.iqc.uwaterloo.ca/mmosca/)at the University of Waterloo.

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

## Acknowledgments

Financial support for the development of Open Quantum Safe has been provided by Amazon Web Services and the Canadian Centre for Cyber Security.

We'd like to make a special acknowledgement to the companies who have dedicated programmer time to contribute source code to OQS, including Amazon Web Services, evolutionQ, Microsoft Research, Cisco Systems, IBM Research and Fachhochschule Nordwestschweiz.

Research projects which developed specific components of OQS have been supported by various research grants, including funding from the Natural Sciences and Engineering Research Council of Canada (NSERC); see here and here for funding acknowledgments.

