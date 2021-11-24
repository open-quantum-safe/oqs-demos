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

# Obtain OQS-specific ids; currently at https://github.com/open-quantum-safe/openssl/tree/mb-wiresharkregistry: TBC
# and patch into wireshark code base
cd epan/dissectors && \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/mb-wiresharkregistry/qsc.h && \
   cd ../.. && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-tls-utils.c && \
   sed -i "s/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");\nQSC_SIGS/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\//    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\/\nQSC_KEMS/g" epan/dissectors/packet-tls-utils.c
 
# Build wireshark
mkdir -p build && cd build && cmake -GNinja .. && ninja 

# Install wireshark
# ninja install

