[![open-quantum-safe](https://circleci.com/gh/open-quantum-safe/oqs-demos.svg?style=svg)](https://app.circleci.com/pipelines/github/open-quantum-safe/oqs-demos)

# oqs-demos

## Purpose

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.  Pre-built Docker images may also be available.

Currently supported packages:

|                  | **Build instructions**                 | **Pre-built Docker image or binary files**                                                                                   |
| ---------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **curl**         | [Github: oqs-demos/curl](curl)         | [Dockerhub: openquantumsafe/curl](https://hub.docker.com/repository/docker/openquantumsafe/curl)                             |
| **Apache httpd** | [Github: oqs-demos/httpd](httpd)       | [Dockerhub: openquantumsafe/httpd](https://hub.docker.com/repository/docker/openquantumsafe/httpd)                           |
| **nginx**        | [Github: oqs-demos/nginx](nginx)       | [Dockerhub: openquantumsafe/nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx)                           |
| **Chromium**     | [Github: oqs-demos/chromium](chromium) | [Binary for Ubuntu 18.04](https://github.com/open-quantum-safe/oqs-demos/releases/download/v0.4.0/chromium-ubuntu-0.4.0.tgz) |
| **HAproxy**      | [Github: oqs-demos/haproxy](haproxy)   | [Dockerhub: openquantumsafe/haproxy](https://hub.docker.com/repository/docker/openquantumsafe/haproxy)                       |
| **OpenSSH**      | [Github: oqs-demos/openssh](openssh)   | [Dockerhub: openquantumsafe/openssh](https://hub.docker.com/repository/docker/openquantumsafe/openssh)                       |

You can use the curl and Chromium clients with the Open Quantum Safe test server at https://test.openquantumsafe.org/.

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
    ISE @ FHNW (Fachhochschule Nordwestscheiz)

## Acknowledgments

Financial support for the development of Open Quantum Safe has been provided by Amazon Web Services and the Tutte Institute for Mathematics and Computing.

We'd like to make a special acknowledgement to the companies who have dedicated programmer time to contribute source code to OQS, including Amazon Web Services, evolutionQ, Microsoft Research, Cisco Systems, IBM Research and Fachhochschule Nordwestschweiz.

Research projects which developed specific components of OQS have been supported by various research grants, including funding from the Natural Sciences and Engineering Research Council of Canada (NSERC); see here and here for funding acknowledgments.

