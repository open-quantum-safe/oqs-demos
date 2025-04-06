# Original Dockerfile written by Chia-Chin Chung <60947091s@gapps.ntnu.edu.tw>

# Define build arguments for version tags, installation paths, and configurations.
ARG UBUNTU_VERSION=24.04
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.12.0
ARG OQSPROVIDER_TAG=0.8.0
ARG MOSQUITTO_TAG=v2.0.20
ARG INSTALLDIR=/opt/oqssa
ARG KEM_ALGLIST="mlkem768:p384_mlkem768"
ARG SIG_ALG="mldsa65"
ARG BROKER_IP=localhost
ARG PUB_IP=localhost
ARG SUB_IP=localhost
ARG EXAMPLE=broker-start.sh

# First stage: the full build image:
FROM ubuntu:${UBUNTU_VERSION} AS builder

# Set timezone
ARG TZ=Europe/London
ENV DEBIAN_FRONTEND=noninteractive

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG KEM_ALGLIST
ARG MOSQUITTO_TAG

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake gcc libtool libssl-dev \
    make ninja-build git doxygen libcjson1 libcjson-dev \
    uthash-dev libcunit1-dev libsqlite3-dev xsltproc docbook-xsl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone source repositories
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${MOSQUITTO_TAG} https://github.com/eclipse/mosquitto.git

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" .. -DOQS_DIST_BUILD=ON -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && \
    ninja install

# Build and install OpenSSL with rpath pointing to custom lib64
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix="${INSTALLDIR}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi

# Update PATH to use newly installed OpenSSL
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build and install OQS provider, activate it by editing openssl.cnf
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build && \
    cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" ${INSTALLDIR}/ssl/openssl.cnf

# Build and install Mosquitto
WORKDIR /opt/mosquitto
RUN make -j"$(nproc)" && make install

# Second stage: Only create minimal image:
FROM ubuntu:${UBUNTU_VERSION}
RUN apt-get update && apt-get install -y --no-install-recommends libcjson1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
ENV TLS_DEFAULT_GROUPS=${KEM_ALGLIST}
ARG INSTALLDIR

# Copy scripts and set permissions
WORKDIR /test
COPY . .
RUN chmod +x /test/* && sed -i 's/\r//' /test/*

# Copy built artifacts from builder stage
COPY --from=builder ${INSTALLDIR} ${INSTALLDIR}
COPY --from=builder /usr/local/lib  /usr/local/lib
COPY --from=builder /usr/local/bin  /usr/local/bin
COPY --from=builder /usr/local/sbin /usr/local/sbin

# Set up dynamic linking to mosquitto and OpenSSL
RUN ln -s /usr/local/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && ldconfig
ENV LD_LIBRARY_PATH=${INSTALLDIR}/lib64
ENV PATH="/usr/local/bin:/usr/local/sbin:${INSTALLDIR}/bin:$PATH"

# Generate the CA key and the certificate
RUN openssl req -x509 -new -newkey $SIG_ALG -keyout /test/CA.key -out /test/CA.crt -nodes -subj "/O=test-ca" -days 3650

# Expose MQTTS port
EXPOSE 8883

# Default command to run the provided example script
WORKDIR /test
CMD ["/bin/bash", "-c", "$EXAMPLE"]
STOPSIGNAL SIGTERM
