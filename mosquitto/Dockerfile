# Original Dockerfile made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
# Multi-stage build: First the full builder image:

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.6.5

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.16.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.12.0

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Default KEM algorithms to be utilized
ARG KEM_ALGLIST="frodo640aes"

# Default Signature algorithm to be used
ARG SIG_ALG="mayo2"

ARG MOSQUITTO_TAG=v2.1.4
ARG MAKE_DEFINES="-j4"

# Broker name and client certificate identities
ARG BROKER_IP=localhost
ARG PUB_IP=publisher
ARG SUB_IP=subscriber

# choose the shell script(simple example)
ARG EXAMPLE=broker-start.sh

# First stage: the full build image:
FROM ubuntu:24.04 AS builder

# Set timezone
ARG TZ=Europe/London
ENV DEBIAN_FRONTEND=noninteractive

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG LIBOQS_BUILD_DEFINES
ARG KEM_ALGLIST
ARG MOSQUITTO_TAG
ARG MAKE_DEFINES

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
    cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DCMAKE_INSTALL_LIBDIR=lib64 && \
    ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix=${INSTALLDIR} --libdir=lib64 && \
    make ${MAKE_DEFINES} && \
    make install_sw install_ssldirs

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
RUN make ${MAKE_DEFINES} CPPFLAGS="-I${INSTALLDIR}/include" LDFLAGS="-L${INSTALLDIR}/lib64 -Wl,-rpath,${INSTALLDIR}/lib64" \
        WITH_DOCS=no WITH_SRV=no WITH_HTTP_API=no WITH_EDITLINE=no WITH_SQLITE=no WITH_WEBSOCKETS=no && \
    make CPPFLAGS="-I${INSTALLDIR}/include" LDFLAGS="-L${INSTALLDIR}/lib64 -Wl,-rpath,${INSTALLDIR}/lib64" \
        WITH_DOCS=no WITH_SRV=no WITH_HTTP_API=no WITH_EDITLINE=no WITH_SQLITE=no WITH_WEBSOCKETS=no install

# Second stage: Only create minimal image:
FROM ubuntu:24.04
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

ARG INSTALLDIR

# Copy files from the local storage to a destination in the Docker image
WORKDIR /
RUN mkdir test
ADD . /test
RUN chmod +x /test/*-start.sh

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
ENV OPENSSL_CONF=${INSTALLDIR}/ssl/openssl.cnf
ENV OPENSSL_MODULES=${INSTALLDIR}/lib64/ossl-modules

# Set path
ENV PATH="/usr/local/bin:/usr/local/sbin:${INSTALLDIR}/bin:$PATH"

# Generate the CA key and the cert
RUN openssl req -x509 -new -newkey $SIG_ALG -keyout /test/CA.key -out /test/CA.crt -nodes -subj "/O=test-ca" -days 3650

# Run the broker and clients without root privileges.
RUN useradd --system --user-group --uid 1883 --shell /usr/sbin/nologin mosquitto && \
    chown -R mosquitto:mosquitto /test
USER mosquitto

# MQTTS port
EXPOSE 8883

# Run shell script
WORKDIR /test
CMD /bin/bash $EXAMPLE

STOPSIGNAL SIGTERM
