#!/bin/bash

# Define the wireshark version to be baked in.
WIRESHARK_VERSION=3.4.9

# Define the degree of parallelism when building the image.
MAKE_DEFINES="-j 4"

#sudo apt update && apt upgrade -y

# Get all software packages required for building wireshark:
sudo apt install -y gcc \
            libtool \
            automake \
            autoconf \
            cmake \
            ninja-build \
            git \
            curl \
            perl \
            flex \
            bison \
            python \
            python3 \
            libssl-dev \
            libgcrypt-dev \
            libpcap-dev \
            libc-ares-dev \
            qtbase5-dev qttools5-dev-tools qttools5-dev qtmultimedia5-dev \
            libssh-dev

# Get the source and unpack it.
curl --output wireshark-${WIRESHARK_VERSION}.tar.xz https://2.na.dl.wireshark.org/src/wireshark-${WIRESHARK_VERSION}.tar.xz
rm -rf wireshark-${WIRESHARK_VERSION}
tar xmvf wireshark-${WIRESHARK_VERSION}.tar.xz
cd wireshark-${WIRESHARK_VERSION} 

# TBC: Obtain OQS-specific code; currently at https://github.com/open-quantum-safe/openssl/tree/mb-wiresharkregistry/oqs-scripts
cd epan/dissectors && \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/mb-wiresharkregistry/oqs-scripts/packet-pkcs1.c && \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/mb-wiresharkregistry/oqs-scripts/packet-tls-utils.c && \
   cd ../..
 
# Build wireshark
mkdir -p build && cd build && cmake -GNinja .. && ninja 

# Install wireshark
# ninja install

