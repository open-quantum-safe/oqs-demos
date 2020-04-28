[![open-quantum-safe](https://circleci.com/gh/open-quantum-safe/oqs-demos.svg?style=svg)](https://app.circleci.com/pipelines/github/open-quantum-safe/oqs-demos)

oqs-demos
======================

A repository of instructions (with associated patches and scripts) to enable, through [liboqs](https://github.com/open-quantum-safe/liboqs), the use of quantum-safe cryptography in various application software.

In most cases, Dockerfiles encode the instructions for ease-of-use: Just do `docker build -t <package_name> .`. For more detailed usage instructions (parameters, algorithms, etc.) refer to the README for each package.

Currently supported packages:

- [Curl](curl)
- [Apache httpd](httpd)
- [nginx](nginx)
- [Chromium](chromium) (Build instructions only)
