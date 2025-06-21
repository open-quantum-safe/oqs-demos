This project provides a Docker image to build [Wireshark](https://www.wireshark.org/) with quantum-safe cryptography
support through the [Open Quantum Safe (OQS) provider](https://github.com/open-quantum-safe/oqs-provider). This Docker
image allows Wireshark to analyze network traffic encrypted with post-quantum cryptographic protocols.

## System Requirements

- **Docker**: Ensure [Docker](https://docs.docker.com/get-docker/) is installed and running on your system.
- **X-Window System (for GUI Display)**:
    - **Linux**:
        - Run the following commands to allow Docker to access the display:
          ```
          xhost +local
          export DISPLAY=:0
          ```
    - **Windows**:
        - Install an X server such as [VcXsrv](https://sourceforge.net/projects/vcxsrv/) and configure it with the
          following options:
            - **Disable access control**
            - **Disable native OpenGL**
        - In PowerShell, set the display environment variable:
          ```
          $env:DISPLAY="<your_host_ip>:0"
          ```
    - **macOS**:
      - Ensure [XQuartz](https://www.xquartz.org) is installed and running.
      -  Under **settings > Security**. Enable **"Allow connections from network clients"** and disable **"Authenticate connections"**.
      - Run the following command in the terminal to allow Docker to access the display:
        ```sh
        xhost +
        ```
      - Set the display environment variable in the terminal:
        ```sh
        export DISPLAY=host.docker.internal:0
        ```
      **Notes:** 
      - Every time you open XQuartz, you need to run `xhost +` and `export DISPLAY=host.docker.internal:0` again.
      - Replace `<your_host_ip>` with your system's IP address. Use `:0` as the default display port unless configured
  otherwise.
## Building Instructions

Run the following commands to build and launch Wireshark with OQS support:

```
git clone https://github.com/open-quantum-safe/oqs-demos
cd oqs-demos/wireshark
docker build -t oqs-wireshark .
docker run --rm -it --net=host -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix oqs-wireshark
```

### Explanation of Docker Options

- `--net=host`: Shares the host network with the container.
- `-e DISPLAY`: Sets the display variable for GUI.
- `-v /tmp/.X11-unix:/tmp/.X11-unix`: Mounts the X11 Unix socket for GUI access.

## Project Components

1. **Dockerfile**: Builds Wireshark with OpenSSL, liboqs, and OQS provider.
2. **generate_qsc_header.py**: Processes `oqs-provider/oqs-template/generate.yml` with the `qsc_template.jinja2` to
   generate `qsc.h`,
   defining post-quantum KEMs and SIGs for Wireshark.

## Usage

For detailed usage instructions, refer to [USAGE.md](USAGE.md).

## Build Configuration and Updates

Customize the build using the following Dockerfile arguments:

- **`UBUNTU_VERSION`**: Specifies the Ubuntu version.
- **`WIRESHARK_VERSION`**: Defines the Wireshark version to build.
- **`OPENSSL_TAG`**: Sets the OpenSSL version to build.
- **`LIBOQS_TAG`**: Specifies the liboqs version to include.
- **`OQSPROVIDER_TAG`**: Defines the Open Quantum Safe provider version.
- **`INSTALLDIR`**: Sets the installation path for OQS libraries.

To keep the build up-to-date, update the arguments as needed to include the latest versions.