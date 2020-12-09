[![open-quantum-safe](https://circleci.com/gh/open-quantum-safe/oqs-demos.svg?style=svg)](https://app.circleci.com/pipelines/github/open-quantum-safe/oqs-demos)

oqs-demos
=========

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.  Pre-built Docker images may also be available.

Currently supported packages:

|                  | **Build instructions**                 | **Pre-built Docker image or binary files**                                                                                   |
|------------------|----------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| **curl**         | [Github: oqs-demos/curl](curl)         | [Dockerhub: openquantumsafe/curl](https://hub.docker.com/repository/docker/openquantumsafe/curl)                             |
| **Apache httpd** | [Github: oqs-demos/httpd](httpd)       | [Dockerhub: openquantumsafe/httpd](https://hub.docker.com/repository/docker/openquantumsafe/httpd)                           |
| **nginx**        | [Github: oqs-demos/nginx](nginx)       | [Dockerhub: openquantumsafe/nginx](https://hub.docker.com/repository/docker/openquantumsafe/nginx)                           |
| **Chromium**     | [Github: oqs-demos/chromium](chromium) | [Binary for Ubuntu 18.04](https://github.com/open-quantum-safe/oqs-demos/releases/download/v0.4.0/chromium-ubuntu-0.4.0.tgz) |
| **HAproxy**        | [Github: oqs-demos/haproxy](haproxy)       | [Dockerhub: openquantumsafe/haproxy](https://hub.docker.com/repository/docker/openquantumsafe/haproxy)                           |

You can use the curl and Chromium clients with the Open Quantum Safe test server at https://test.openquantumsafe.org/.
