# Original Dockerfile made by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>
# Multi-stage build: First the full builder image:

# Define base OS version and essential component versions/tags
ARG UBUNTU_VERSION=24.04
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.11.0
ARG OQSPROVIDER_TAG=0.7.0
ARG MOSQUITTO_TAG=v2.0.20

# Installation directory for compiled binaries
ARG INSTALLDIR=/opt/oqssa

# Define default quantum-safe algorithm configurations
ARG KEM_ALGLIST="kyber768:p384_kyber768"
ARG SIG_ALG="dilithium3"

# Network configurations
ARG BROKER_IP=localhost
ARG PUB_IP=localhost
ARG SUB_IP=localhost

# Shell script to be executed (default example)
ARG EXAMPLE=broker-start.sh

# First stage: the full build image:
FROM ubuntu:${UBUNTU_VERSION} AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG MOSQUITTO_TAG
ARG INSTALLDIR
ARG KEM_ALGLIST

# Install necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake gcc libtool ca-certificates \
    libssl-dev make ninja-build git \
    doxygen libcjson1 libcjson-dev uthash-dev \
    libcunit1-dev libsqlite3-dev xsltproc docbook-xsl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Get all required sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${MOSQUITTO_TAG} https://github.com/eclipse/mosquitto.git

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" .. -DOQS_DIST_BUILD=ON \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && \
    ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" \
    ./config shared --prefix="${INSTALLDIR}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi

# Set PATH to include the new OpenSSL binaries
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build, install, and activate OQS-Provider
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR}  \
    -DCMAKE_BUILD_TYPE=Release  \
    -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && \
    # Update OpenSSL configuration to include OQS-Provider
    cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf

# Build and install Mosquitto
WORKDIR /opt/mosquitto
RUN make -j"$(nproc)" && make install

# Second stage: Only create minimal image:
FROM ubuntu:${UBUNTU_VERSION}

# Install necessary runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libcjson1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# Set variables for installation, cryptography, networking, and runtime behavior.
ARG INSTALLDIR
ARG SIG_ALG
ARG BROKER_IP
ARG PUB_IP
ARG SUB_IP
ARG EXAMPLE
ARG KEM_ALGLIST

ENV SIG_ALG=${SIG_ALG}
ENV BROKER_IP=${BROKER_IP}
ENV PUB_IP=${PUB_IP}
ENV SUB_IP=${SUB_IP}
ENV EXAMPLE=${EXAMPLE}

# Define QSC KEM groups for OpenSSL, prioritizing those specified in the configuration or defaults
ENV TLS_DEFAULT_GROUPS=${KEM_ALGLIST}

# Copy testing shell scripts to the container
WORKDIR /test
COPY . .
RUN chmod 777 /test/*

# Copy required files from the builder stage
COPY --from=builder ${INSTALLDIR} ${INSTALLDIR}
COPY --from=builder /usr/local/lib  /usr/local/lib
COPY --from=builder /usr/local/bin  /usr/local/bin
COPY --from=builder /usr/local/sbin  /usr/local/sbin

# Link Mosquitto library and update cache
RUN ln -s /usr/local/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && ldconfig

# Set OpenSSL library path
ENV LD_LIBRARY_PATH=$INSTALLDIR/lib64

# Update executable search path
ENV PATH="/usr/local/bin:/usr/local/sbin:${INSTALLDIR}/bin:$PATH"

# Generate CA key and certificate for MQTT
RUN openssl req -x509 -new -newkey $SIG_ALG -keyout /test/CA.key -out /test/CA.crt -nodes -subj "/O=test-ca" -days 3650

# Expose MQTT TLS port
EXPOSE 8883

# Run testing shell scripts
WORKDIR /test
CMD ["/bin/bash", "-c", "$EXAMPLE"]

# Set termination signal
STOPSIGNAL SIGTERM