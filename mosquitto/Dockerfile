# This Dockerfile is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
# Multi-stage build

# Global build arguments:

# define the installation paths
ARG SOURCE_PATH="/usr/local/src"
ARG OPENSSL_LIB_PATH="/usr/local/ssl"

# liboqs build type variant; limit to algorithms that are supported by wolfMQTT
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON  -DOQS_MINIMAL_BUILD=OQS_ENABLE_KEM_kyber_512;OQS_ENABLE_SIG_falcon_512 "

# openssl build defines (https://github.com/open-quantum-safe/openssl#build-options)
# limit to groups supported by wolfMQTT
ARG OPENSSL_BUILD_DEFINES="-DOQS_DEFAULT_GROUPS=kyber512:p256_kyber512"

# define the QSC signature algorithm used for the certificates
# limit to signature algorithm supported by wolfMQTT
ARG SIG_ALG="falcon512"

# define IP addresses or Domain Name
ARG BROKER_IP=localhost
ARG PUB_IP=localhost
ARG SUB_IP=localhost

# choose the shell script(simple example)
ARG EXAMPLE=broker-start.sh


# First stage: the full build image:

FROM ubuntu:20.04 AS builder
# FROM debian:buster AS builder

# Set timezone
ENV TZ=Asia/Taipei
ENV DEBIAN_FRONTEND=noninteractive

ARG SOURCE_PATH
ARG OPENSSL_LIB_PATH
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_BUILD_DEFINES

# Update image and install all prerequisites
RUN apt update && apt install build-essential vim cmake gcc libtool libssl-dev make ninja-build git doxygen \
        libcjson1 libcjson-dev uthash-dev libcunit1-dev libsqlite3-dev xsltproc docbook-xsl -y && apt clean

# Get the fork of OQS-OpenSSL_1_1_1-stable-snapshot-2021-08
WORKDIR $SOURCE_PATH
RUN git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable-snapshot-2021-08 https://github.com/open-quantum-safe/openssl.git OQS-OpenSSL

# Get and build liboqs, then install it into a subdirectory inside the OQS-OpenSSL folder
# Use the commit that is supported by wolfSSL
RUN git clone --single-branch --branch main https://github.com/open-quantum-safe/liboqs.git liboqs && \
    cd liboqs && git checkout ba5b61a779a0db364f0e691a0a0bc8ac42e73f1b && mkdir build && cd build && \
    cmake -GNinja $LIBOQS_BUILD_DEFINES -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$SOURCE_PATH/OQS-OpenSSL/oqs .. && \
    ninja && ninja install && echo "liboqs installed successfully" || exit 1

# Build and install OQS-OpenSSL_1_1_1-stable
WORKDIR $SOURCE_PATH/OQS-OpenSSL
## OS type: x86_64, aarch64
RUN ./Configure shared linux-x86_64 -lm --prefix=$OPENSSL_LIB_PATH/ \
        --openssldir=$OPENSSL_LIB_PATH/ $OPENSSL_BUILD_DEFINES && \
        make -j$(nproc) && make install && echo "OQS-OpenSSL installed successfully" || exit 1
# RUN ./Configure shared no-asm linux-aarch64 -lm --prefix=$OPENSSL_LIB_PATH/ \
#         --openssldir=$OPENSSL_LIB_PATH/ $OPENSSL_BUILD_DEFINES && \
#         make -j$(nproc) && make install && echo "OQS-OpenSSL installed successfully" || exit 1

# Build and install Mosquitto
WORKDIR $SOURCE_PATH
RUN git clone -b master https://github.com/eclipse/mosquitto.git mosquitto && cd mosquitto && \
    make -j$(nproc) && make install && echo "Mosquitto installed successfully" || exit 1


# Second stage: Only create minimal image:

FROM ubuntu:20.04
# FROM debian:buster

ARG OPENSSL_LIB_PATH
ARG SIG_ALG
ENV SIG_ALG=${SIG_ALG}
ARG BROKER_IP
ENV BROKER_IP=${BROKER_IP}
ARG PUB_IP
ENV PUB_IP=${PUB_IP}
ARG SUB_IP
ENV SUB_IP=${SUB_IP}
ARG EXAMPLE
ENV EXAMPLE=${EXAMPLE}

# Set the TLS_DEFAULT_GROUPS environment variable to permit selection of QSC KEMs(https://github.com/open-quantum-safe/openssl#build-options)
ENV TLS_DEFAULT_GROUPS="kyber512"

# Copy files from the local storage to a destination in the Docker image
WORKDIR /
RUN mkdir test
ADD . /test
RUN chmod 777 /test/* && sed -i 's/\r//' /test/*

# Only keep the necessary library contents in the final image
# OQS-OpenSSL
COPY --from=builder $OPENSSL_LIB_PATH  $OPENSSL_LIB_PATH
# Mosquitto
COPY --from=builder /usr/local/lib  /usr/local/lib
COPY --from=builder /usr/local/bin  /usr/local/bin
COPY --from=builder /usr/local/sbin  /usr/local/sbin
COPY --from=builder /lib/x86_64-linux-gnu/libcjson.so.1 /lib/x86_64-linux-gnu

# Dynamically link to mosquitto
RUN ln -s /usr/local/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && ldconfig

# Dynamically link to OQS-OpenSSL library
ENV LD_LIBRARY_PATH=$OPENSSL_LIB_PATH/lib

# Set path 
ENV PATH="/usr/local/bin:/usr/local/sbin:$OPENSSL_LIB_PATH/bin:$PATH"

# Generate the CA key and the cert
RUN openssl req -x509 -new -newkey $SIG_ALG -keyout /test/CA.key -out /test/CA.crt -nodes -subj "/O=test-ca" -days 3650

# MQTTS port 
EXPOSE 8883

# Run shell script
WORKDIR /test
CMD /bin/bash $EXAMPLE

STOPSIGNAL SIGTERM
