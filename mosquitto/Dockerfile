# Original Dockerfile made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
# Multi-stage build: First the full builder image:

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.4.0

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.13.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.9.0

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Default KEM algorithms to be utilized
ARG KEM_ALGLIST="mlkem768:p384_mlkem768"

# Default Signature algorithm to be used
ARG SIG_ALG="mldsa65"

ARG MOSQUITTO_TAG=v2.0.20

# define IP addresses or Domain Name
ARG BROKER_IP=localhost
ARG PUB_IP=localhost
ARG SUB_IP=localhost

# choose the shell script(simple example)
ARG EXAMPLE=broker-start.sh

# First stage: the full build image:
FROM ubuntu:22.04 AS builder

# Set timezone
ARG TZ=Europe/London
ENV DEBIAN_FRONTEND=noninteractive

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG HAPROXYDIR
ARG LIBOQS_BUILD_DEFINES
ARG KEM_ALGLIST
ARG MOSQUITTO_TAG

# Update image and install all prerequisites
RUN apt update && apt install -y build-essential \
    cmake \
    gcc \
    libtool \
    libssl-dev \
    make \
    ninja-build \
    git \
    doxygen \
    libcjson1 \
    libcjson-dev \
    uthash-dev \
    libcunit1-dev \
    libsqlite3-dev \
    xsltproc \
    docbook-xsl && \
    apt clean

# get all sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${MOSQUITTO_TAG} https://github.com/eclipse/mosquitto.git

# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build && cd build && \
    cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && \
    ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix=${INSTALLDIR} && \
    make -j $(nproc) && \
    make install_sw install_ssldirs && \
    if [ -d ${INSTALLDIR}/lib64 ]; then ln -s ${INSTALLDIR}/lib64 ${INSTALLDIR}/lib; fi && \
    if [ -d ${INSTALLDIR}/lib ]; then ln -s ${INSTALLDIR}/lib ${INSTALLDIR}/lib64; fi

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf

# Build and install Mosquitto
WORKDIR /opt/mosquitto
RUN make -j$(nproc) && \
    make install

# Second stage: Only create minimal image:
FROM ubuntu:22.04
RUN apt update && apt install -y libcjson1

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

ARG KEM_ALGLIST
# Set the TLS_DEFAULT_GROUPS environment variable to permit selection of QSC KEMs, by default the ones associated with the openssl configuration are chosen
ENV TLS_DEFAULT_GROUPS=${KEM_ALGLIST}

ARG INSTALLDIR

# Copy files from the local storage to a destination in the Docker image
WORKDIR /
RUN mkdir test
ADD . /test
RUN chmod 777 /test/* && sed -i 's/\r//' /test/*

# openssl
COPY --from=builder ${INSTALLDIR} ${INSTALLDIR}
# Mosquitto
COPY --from=builder /usr/local/lib  /usr/local/lib
COPY --from=builder /usr/local/bin  /usr/local/bin
COPY --from=builder /usr/local/sbin  /usr/local/sbin

# Dynamically link to mosquitto
RUN ln -s /usr/local/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && ldconfig

# Dynamically link to Newly built OpenSSL
ENV LD_LIBRARY_PATH=$INSTALLDIR/lib64

# Set path
ENV PATH="/usr/local/bin:/usr/local/sbin:${INSTALLDIR}/bin:$PATH"

# Generate the CA key and the cert
RUN openssl req -x509 -new -newkey $SIG_ALG -keyout /test/CA.key -out /test/CA.crt -nodes -subj "/O=test-ca" -days 3650

# MQTTS port
EXPOSE 8883

# Run shell script
WORKDIR /test
CMD /bin/bash $EXAMPLE

STOPSIGNAL SIGTERM
