# Define build arguments for version tags, installation paths, and configurations

ARG UBUNTU_VERSION=24.04
ARG INSTALLDIR=/opt/oqssa

# OpenSSL/OQS Versions
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0

# Nodejs specific versions, Always use an LTS version for nodejs
ARG NODEJS_VERSION=v22.16.0
ARG CARES_VERSION=1.28.0
ARG LIBUV_VERSION=v1.50.0

# Specify supported key encapsulation mechanisms (KEM) algorithms
ARG KEM_ALGLIST="mlkem768:p384_mlkem768"

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM ubuntu:${UBUNTU_VERSION} AS intermediate
LABEL version="3"

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG KEM_ALGLIST

ENV DEBIAN_FRONTEND=noninteractive
ENV OPENSSL3_DIR=${INSTALLDIR}

# Install required build tools and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
            libtool automake autoconf cmake ninja-build ca-certificates \
            make openssl libssl-dev pkg-config \
            git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and prepare source files needed for the build process
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" ..  \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && ninja install

# Build and install OpenSSL
WORKDIR /opt/openssl
RUN openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/$openssl_libdir" ./config shared --prefix=${INSTALLDIR} && \
    make -j"$(nproc)" && make install_sw install_ssldirs;

# Set PATH to include the new OpenSSL binaries
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build, install, and configure the oqs-provider for OpenSSL integration
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/$openssl_libdir/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf

# Build Nodejs
ARG NODEJS_VERSION
ARG CARES_VERSION
ARG LIBUV_VERSION

# install some build tools and libraries for node building
RUN apt update && apt install -y --no-install-recommends \
    build-essential wget python3 \
    libnghttp2-dev libbrotli-dev zlib1g-dev

# we need a newer version of libuv than ubuntu provides
WORKDIR /opt
RUN git clone https://github.com/libuv/libuv.git && \
    cd libuv && \
    echo "starting libuv $libuv_tag tag verification & checkout" && \
    git checkout $LIBUV_VERSION

WORKDIR /opt/libuv
RUN sh autogen.sh && \
    ./configure \
          --prefix=${INSTALLDIR} \
          CFLAGS="-O3 -fPIC" \
          && \
    make -j $(nproc) && \
    make -j $(nproc) install

# we need a newer version of c-ares than ubuntu provides
WORKDIR /opt/cares
RUN export cares_path=$(echo "$CARES_VERSION" | tr . _) && \
    wget https://github.com/c-ares/c-ares/releases/download/cares-${cares_path}/c-ares-${CARES_VERSION}.tar.gz && \
    tar -xzvf c-ares-${CARES_VERSION}.tar.gz >/dev/null && \
    rm -f c-ares-${CARES_VERSION}.tar.gz* && \
    cd c-ares-${CARES_VERSION} && \
    mkdir build && cd build && \
    cmake \
         -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} \
         -DCMAKE_BUILD_TYPE=Release \
         -DCARES_STATIC=ON \
         -DCARES_SHARED=ON \
         -DCARES_INSTALL=ON \
         -DCMAKE_INSTALL_SO_NO_EXE=OFF \
         .. \
    && \
    $deployment_dir/bin/make -j $(nproc) && \
    $deployment_dir/bin/make install

# Download and build Node. This takes a long time.
WORKDIR /opt
RUN git clone https://github.com/nodejs/node.git && \
    cd node && \
    git checkout ${NODEJS_VERSION} && \
    openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    export LDFLAGS="-L${INSTALLDIR}/${openssl_libdir} -lssl -lcrypto -Wl,-rpath,${INSTALLDIR}/${openssl_libdir} \
                    -L${INSTALLDIR}/lib64 -lcares -Wl,-rpath,${INSTALLDIR}/lib64 \
                    -L${INSTALLDIR}/lib -luv -Wl,-rpath,${INSTALLDIR}/lib" && \
    export CPPFLAGS="-I${INSTALLDIR}/include \
                     -fno-omit-frame-pointer" && \
    ./configure \
            --prefix=${INSTALLDIR} \
            --verbose \
            --shared-libuv \
            --shared-nghttp2 \
            --shared-openssl \
            --shared-zlib \
            --shared-cares \
            --shared-brotli \
            --openssl-conf-name openssl_conf \
            && \
    echo "configure: Done" && \
    $deployment_dir/bin/make -j $(nproc) && \
    $deployment_dir/bin/make install

# Stage 2, copy to clean image
FROM ubuntu:${UBUNTU_VERSION}

ARG INSTALLDIR

# Copy only the required contents from the intermediate stage
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# Install dependencies
RUN apt update && apt install -y --no-install-recommends libbrotli1 libnghttp2-14

# Set PATH
ENV PATH="${INSTALLDIR}/bin:${PATH}"

