# Define the wireshark version to be baked in.
ARG WIRESHARK_VERSION=3.4.9

# Define the degree of parallelism when building the image.
ARG MAKE_DEFINES="-j 4"

FROM ubuntu as intermediate
ENV DEBIAN_FRONTEND noninteractive


ARG WIRESHARK_VERSION
ARG MAKE_DEFINES

RUN apt update && apt upgrade -y

# Get all software packages required for building wireshark:
RUN apt install -y gcc g++ \
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
            wget \
            libssh-dev

# Get the source and unpack it.
WORKDIR /opt
RUN curl --output wireshark-${WIRESHARK_VERSION}.tar.xz https://2.na.dl.wireshark.org/src/wireshark-${WIRESHARK_VERSION}.tar.xz
RUN rm -rf wireshark-${WIRESHARK_VERSION}
RUN tar xmvf wireshark-${WIRESHARK_VERSION}.tar.xz

WORKDIR /opt/wireshark-${WIRESHARK_VERSION} 

# TBC: Obtain OQS-specific code; currently at https://github.com/open-quantum-safe/openssl/tree/mb-wiresharkregistry/oqs-scripts
RUN cd epan/dissectors && \
   rm packet-pkcs1.c packet-tls-utils.c && \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/mb-wiresharkregistry/oqs-scripts/packet-pkcs1.c && \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/mb-wiresharkregistry/oqs-scripts/packet-tls-utils.c 

# Build wireshark
RUN mkdir -p build && cd build && cmake -GNinja .. && ninja && ninja install

CMD wireshark
