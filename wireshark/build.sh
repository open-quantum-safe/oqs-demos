#!/bin/bash

# Define the wireshark version to be used
WIRESHARK_VERSION=3.4.9

# Define the SSL naming convention: One of "wolfssl" and "oqs"
QSC_SSL_FLAVOR="oqs"

if [ $QSC_SSL_FLAVOR == "oqs" ]; then
   # Obtain OQS-specific ids 
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/OQS-OpenSSL_1_1_1-stable/qsc.h 
elif [ $QSC_SSL_FLAVOR == "wolfssl" ]; then
   mv wolfssl-qsc.h qsc.h
else
   echo "Unknown naming convention. Exiting."
   exit -1
fi

sudo apt update && apt upgrade -y

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
curl --output wireshark-${WIRESHARK_VERSION}.tar.xz https://2.na.dl.wireshark.org/src/all-versions/wireshark-${WIRESHARK_VERSION}.tar.xz
rm -rf wireshark-${WIRESHARK_VERSION}
tar xmvf wireshark-${WIRESHARK_VERSION}.tar.xz

cd wireshark-${WIRESHARK_VERSION} 

# patch wireshark code base with IDs
cp oqs.h epan/dissectors && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-tls-utils.c && \
   sed -i "s/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");\nQSC_SIGS/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\//    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\/\nQSC_KEMS/g" epan/dissectors/packet-tls-utils.c
 
# Build wireshark
mkdir -p build && cd build && cmake -GNinja .. && ninja 

# Install wireshark
# ninja install

