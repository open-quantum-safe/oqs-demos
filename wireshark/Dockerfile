# Define the wireshark version to be baked in.
ARG WIRESHARK_VERSION=3.4.9

# Define the degree of parallelism when building the image.
ARG MAKE_DEFINES="-j 4"

FROM alpine:3.11 as intermediate

# Take in all global args
ARG WIRESHARK_VERSION
ARG MAKE_DEFINES

ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

# Get all software packages required for building wireshark:
RUN apk add build-base \
            linux-headers \
            libtool \
            automake \
            autoconf \
            cmake \
            make \
            git \
            curl \
            perl \
            flex \
            bison \
            python \
            python3 \
            openssl-dev \
            libgcrypt-dev \
            c-ares-dev \
            qt5-qttools-dev \
            qt5-qtmultimedia-dev \
            libpcap-dev \
            libssh-dev

# Get the source and unpack it.
WORKDIR /opt
run curl --output wireshark-${WIRESHARK_VERSION}.tar.xz https://2.na.dl.wireshark.org/src/wireshark-${WIRESHARK_VERSION}.tar.xz
RUN rm -rf wireshark-${WIRESHARK_VERSION}
RUN tar xmvf wireshark-${WIRESHARK_VERSION}.tar.xz
WORKDIR /opt/wireshark-${WIRESHARK_VERSION}

# Apply the patch.
COPY wolfssl_pq_codepoints_oids.patch ./
RUN patch -p1 < wolfssl_pq_codepoints_oids.patch
 
# Build wireshark!!
RUN mkdir build && cd build && cmake .. && make all && make install

