# Multi-stage build: First the full builder image:

# Define build arguments for version tags, installation paths, and configurations.
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.12.0
ARG OQSPROVIDER_TAG=0.8.0
ARG NGHTTP2_TAG=v1.64.0
ARG INSTALLDIR=/opt/oqssa

# Stage 1: Build - Compile and assemble all necessary components and dependencies.
FROM alpine:${ALPINE_VERSION} AS intermediate
ARG INSTALLDIR
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG NGHTTP2_TAG

# Install required build tools and system dependencies.
RUN apk update && apk --no-cache add bash git g++ make cmake ninja autoconf automake libtool \
    libev-dev libevent-dev openssl-dev openssl zlib c-ares-dev pkgconfig \
    linux-headers zlib-dev jansson-dev

# Download and prepare source files needed for the build process.
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${NGHTTP2_TAG} https://github.com/nghttp2/nghttp2.git

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -GNinja -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} ..  \
    && ninja && ninja install

# Build and install OpenSSL
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix="${INSTALLDIR}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi

# Build, install, and configure the oqs-provider for OpenSSL integration.
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build && \
    cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:KEM_ALG\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\# Use this in order to automatically load providers/\# Set default KEM alg if not set via environment variable\nKEM_ALG = kyber512\n\n# Use this in order to automatically load providers/g" /opt/oqssa/ssl/openssl.cnf

# Build and install nghttp2
WORKDIR /opt/nghttp2
RUN LD_LIBRARY_PATH="${INSTALLDIR}/lib64" autoreconf -i && automake && autoconf && ./configure \
    PKG_CONFIG_PATH="/opt/oqssa/lib64/pkgconfig" && make -j"$(nproc)" install

# Copy all required shared object dependencies to a single directory
WORKDIR /opt/lib
RUN cp /usr/local/lib/libnghttp2.so.* . && \
    cp /usr/lib/libev.so.* . && \
    cp /opt/oqssa/lib64/libssl.so.* . && \
    cp /opt/oqssa/lib64/libcrypto.so.* . && \
    cp /usr/lib/libstdc++.so.* . && \
    cp /usr/lib/libgcc_s.so.* .

# Stage 2: Runtime - Create a lightweight image with essential binaries and configurations.
FROM alpine:${ALPINE_VERSION} AS dev

# copy executable
COPY --from=intermediate /usr/local/bin/h2load /usr/local/bin
COPY check_algorithms.sh /usr/local/bin

# copy shared object dependencies and configuration file
COPY --from=intermediate /opt/lib /usr/local/lib
COPY --from=intermediate /opt/oqssa/lib64/ossl-modules/oqsprovider.so /opt/oqssa/lib64/ossl-modules/oqsprovider.so
COPY --from=intermediate /opt/oqssa/ssl/openssl.cnf /opt/oqssa/ssl/openssl.cnf

RUN ln -s /opt/oqssa/lib64 /opt/oqssa/lib;
