# This Dockerfile is made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
# Multi-stage build

# Global build arguments:

# define the installation paths
ARG SOURCE_PATH="/usr/local/src"
ARG OPENSSL_LIB_PATH="/usr/local/ssl"

# define the QSC key exchange algorithm
ARG KEM_ALG="kyber512"

# define the QSC signature algorithm used for the certificates
ARG SIG_ALG="dilithium2"

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
ARG KEM_ALG

# Copy files from the local storage to a destination in the Docker image
WORKDIR /
RUN mkdir test
ADD kem_list.txt /test
RUN chmod 777 /test/* && sed -i 's/\r//' /test/*

# Update image and install all prerequisites
RUN apt update && apt install build-essential vim cmake gcc libtool libssl-dev make ninja-build git doxygen \
        libcjson1 libcjson-dev uthash-dev libcunit1-dev libsqlite3-dev xsltproc docbook-xsl -y && apt clean

# Get the fork of OQS-OpenSSL_1_1_1-stable
WORKDIR $SOURCE_PATH
RUN git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl.git OQS-OpenSSL

# Get and build liboqs, then install it into a subdirectory inside the OQS-OpenSSL folder
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs.git liboqs && \
    cd liboqs && mkdir build && cd build && \
    cmake -GNinja -DCMAKE_INSTALL_PREFIX=$SOURCE_PATH/OQS-OpenSSL/oqs .. && \
    ninja && ninja install && echo "liboqs installed successfully" || exit 1

# Build and install OQS-OpenSSL_1_1_1-stable
WORKDIR $SOURCE_PATH/OQS-OpenSSL
## OS type: x86_64, aarch64
RUN ./Configure shared linux-x86_64 -lm --prefix=$OPENSSL_LIB_PATH/ \
        --openssldir=$OPENSSL_LIB_PATH/ -DOQS_DEFAULT_GROUPS=\"$KEM_ALG\"
# RUN ./Configure shared no-asm linux-aarch64 -lm --prefix=$OPENSSL_LIB_PATH/ \
#         --openssldir=$OPENSSL_LIB_PATH/ -DOQS_DEFAULT_GROUPS=\"$KEM_ALG\"

# Let Mosquitto Client to support KEM algorithm
RUN CP=`grep "\/\* $KEM_ALG \*\/" /test/kem_list.txt | awk '{print $1}'` && \
    sed -i '/static const uint16_t eccurves_default/a\    '$CP'                      \/\* '$KEM_ALG' \*\/' ssl/t1_lib.c && \
    make -j$(nproc) && make install && echo "OQS-OpenSSL installed successfully" || exit 1

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

# MQTTS port 
EXPOSE 8883

# Run shell script
WORKDIR /test
CMD /bin/bash $EXAMPLE

STOPSIGNAL SIGTERM
