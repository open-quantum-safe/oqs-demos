This project provides a Docker image to build [Wireshark](https://www.wireshark.org/) with quantum-safe cryptography
support through the [Open Quantum Safe (OQS) provider](https://github.com/open-quantum-safe/oqs-provider). This Docker
image allows Wireshark to analyze network traffic encrypted with post-quantum cryptographic protocols.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Start Guide](#quick-start-guide)
3. [Project Components](#project-components)
4. [Running Wireshark with OQS](#running-wireshark-with-oqs)
    - [Explanation of Docker Options](#explanation-of-docker-options)
5. [Testing Quantum-Safe Protocols](#testing-quantum-safe-protocols)
6[Build Configuration and Updates](#build-configuration-and-updates)

## System Requirements

- **Docker**: Ensure [Docker](https://docs.docker.com/get-docker/) is installed and running on your system.
- **X-Window System (for GUI Display)**:
    - **Linux**: Run `xhost +si:localuser:$USER` to allow Docker to access the display.
    - **Windows/macOS**: Install an X server such as [VcXsrv](https://sourceforge.net/projects/vcxsrv/) (Windows)
      or [XQuartz](https://www.xquartz.org/) (macOS) and start it, ensuring to **disable access control** and **disable
      native OpenGL**.

## Quick Start Guide

```bash
git clone https://github.com/open-quantum-safe/oqs-demos
cd oqs-demos/wireshark
docker build -t wireshark-oqs .
docker run --rm -it --net=host -e DISPLAY=<your_host_ip>:<your_display_port> -v /tmp/.X11-unix:/tmp/.X11-unix wireshark-oqs
```

Replace `<your_host_ip>` with your IP address (e.g., `192.168.x.x`) and `<your_display_port>` with your display port,
typically `:0`.

## Project Components

1. **Dockerfile**: Builds Wireshark with OpenSSL, liboqs, and OQS provider.
2. **generate_qsc_header.py**: Downloads and processes algorithm definitions from the OQS provider repository,
   generating `qsc.h` to define post-quantum cryptographic algorithms for Wireshark.

## Running Wireshark

You can run the Wireshark Docker container on Linux, Windows, or macOS using the following command:

  ```bash
  docker run --rm -it --net=host -e DISPLAY=<your_host_ip>:<your_display_port> -v /tmp/.X11-unix:/tmp/.X11-unix wireshark-oqs
  ```
  Replace `<your_host_ip>` with your IP address (e.g., `192.168.x.x`) and `<your_display_port>` with your display port,
  typically `:0`.

### Explanation of Docker Options

- `--net=host`: Shares the host network with the container.
- `-e DISPLAY`: Sets the display variable for GUI.
- `-v /tmp/.X11-unix:/tmp/.X11-unix`: Mounts the X11 Unix socket for GUI access.

## Testing Quantum-Safe Protocols

Once Wireshark is running, you can capture and filter quantum-safe cryptographic traffic.
At https://test.openquantumsafe.org, most quantum-safe algorithms from the NIST PQC competition are available for TLS
testing. As a client, we recommend using an OQS-enabled curl Docker image for a quick test.

1. **Filter by Quantum-Safe Protocols**: Use the following Wireshark display filter:
   ```plaintext
   tls && ip.addr == <test.openquantumsafe.org IP>
   ```
   Replace `<test.openquantumsafe.org IP>` with the IP address of `test.openquantumsafe.org`.

2. **Test Quantum-Safe Connections**:
   ```bash
   docker run -it openquantumsafe/curl sh -c "curl -k https://test.openquantumsafe.org:6069 --curves kyber1024"
   ```
   You can replace the port (e.g., `6069`) and the algorithm (e.g., `kyber1024`) in the command with the corresponding
   values from the [Open Quantum Safe test page](https://test.openquantumsafe.org/).

## Build Configuration and Updates

Customize the build using the following Dockerfile arguments:

- **`UBUNTU_VERSION`**: Specifies the Ubuntu version (default: latest stable).
- **`WIRESHARK_VERSION`**: Defines the Wireshark version to build.
- **`INSTALLDIR`**: Sets the installation path for OQS libraries (default: `/opt/oqs`).

Use `--build-arg ARG_NAME=value` in the `docker build` command to adjust these values.

To keep the build up-to-date, the `Dockerfile` and `generate_qsc_header.py` are designed for easy updates:

- Update the Ubuntu and Wireshark versions by modifying the `UBUNTU_VERSION` and `WIRESHARK_VERSION` arguments.
- The `generate_qsc_header.py` script automatically fetches new OQS algorithms, ensuring the latest definitions are
  included.