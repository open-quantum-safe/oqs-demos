# Define build arguments for version tags, installation paths, and configurations
ARG UBUNTU_VERSION=24.04
ARG WIRESHARK_VERSION=4.4.7
ARG OPENSSL_TAG=3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0
ARG INSTALLDIR=/opt/oqs

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM ubuntu:${UBUNTU_VERSION} AS build

LABEL version="4"

ENV DEBIAN_FRONTEND=noninteractive
ARG WIRESHARK_VERSION
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR

# Install required build tools and system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libtool automake autoconf cmake ninja-build \
    git wget ca-certificates  \
    python3 python3-pip python3-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up isolated directories
WORKDIR /opt
RUN mkdir -p src/liboqs src/openssl src/oqs-provider src/wireshark \
    build/liboqs build/openssl build/oqs-provider build/wireshark \
    ${INSTALLDIR}/lib ${INSTALLDIR}/bin ${INSTALLDIR}/ssl

# Download and prepare source files needed for the build process
WORKDIR /opt/src
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs.git liboqs && \
    git clone --depth 1 --branch openssl-${OPENSSL_TAG} https://github.com/openssl/openssl.git openssl && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git oqs-provider && \
    wget -O wireshark.tar.xz https://www.wireshark.org/download/src/all-versions/wireshark-${WIRESHARK_VERSION}.tar.xz && \
    tar -xf wireshark.tar.xz --strip-components=1 -C wireshark && \
    rm wireshark.tar.xz

# Build and install liboqs
WORKDIR /opt/build/liboqs
RUN cmake -G Ninja /opt/src/liboqs \
    -D CMAKE_INSTALL_PREFIX="${INSTALLDIR}/liboqs" \
    -D BUILD_SHARED_LIBS=ON \
    -D OQS_USE_OPENSSL=OFF \
    -D CMAKE_INSTALL_RPATH="${INSTALLDIR}/liboqs/lib" && \
    ninja -j"$(nproc)" && ninja install

# Build and install OpenSSL
WORKDIR /opt/build/openssl
RUN LDFLAGS="-Wl,-rpath,${INSTALLDIR}/liboqs/lib" \
    /opt/src/openssl/config \
        --prefix="${INSTALLDIR}/openssl" \
        --openssldir="${INSTALLDIR}/ssl" \
        shared && \
    make -j"$(nproc)" && \
    make install_sw install_ssldirs

# Build, install, and configure the oqs-provider for OpenSSL integration
WORKDIR /opt/build/oqs-provider
RUN cmake -G Ninja \
    -D OPENSSL_ROOT_DIR="${INSTALLDIR}/openssl" \
    -D CMAKE_PREFIX_PATH="${INSTALLDIR}/openssl;${INSTALLDIR}/liboqs" \
    -D CMAKE_INSTALL_PREFIX="${INSTALLDIR}/oqs-provider" \
    -D CMAKE_INSTALL_RPATH="${INSTALLDIR}/openssl/lib:${INSTALLDIR}/liboqs/lib" \
    /opt/src/oqs-provider && \
    ninja -j"$(nproc)" && \
    mkdir -p "${INSTALLDIR}/openssl/lib/ossl-modules" && \
    cp /opt/build/oqs-provider/lib/oqsprovider.so "${INSTALLDIR}/openssl/lib/ossl-modules" && \
    CONFIG_FILE="${INSTALLDIR}/ssl/openssl.cnf" && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" "$CONFIG_FILE" && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" "$CONFIG_FILE"

# Using a script from Wireshark to install required build dependencies
WORKDIR /opt/src/wireshark
RUN ./tools/debian-setup.sh -y

# Generate `qsc.h`
WORKDIR ${INSTALLDIR}
RUN cp /opt/src/oqs-provider/oqs-template/generate.yml ${INSTALLDIR}
COPY generate_qsc_header.py ${INSTALLDIR}
COPY qsc_template.jinja2 ${INSTALLDIR}
COPY requirements.txt ${INSTALLDIR}

RUN python3 -m venv ${INSTALLDIR}/venv && \
    . ${INSTALLDIR}/venv/bin/activate && \
    pip install -r requirements.txt && \
    python ${INSTALLDIR}/generate_qsc_header.py && \
    deactivate

RUN cp ${INSTALLDIR}/qsc.h /opt/src/wireshark/epan/dissectors/

# Modify Wireshark source files for post-quantum definitions
WORKDIR /opt/src/wireshark
RUN sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-pkcs1.c && \
    sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-tls-utils.c && \
    sed -i "s/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");\nQSC_SIGS/g" epan/dissectors/packet-pkcs1.c && \
    sed -i "s/    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\//    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\/\nQSC_KEMS/g" epan/dissectors/packet-tls-utils.c && \
    sed -i "s/ { 0x080b\, \"rsa_pss_pss_sha512\" }\,/ { 0x080b\, \"rsa_pss_pss_sha512\" }\,\nQSC_SIG_CPS/g" epan/dissectors/packet-tls-utils.c

# Build and install Wireshark
WORKDIR /opt/build/wireshark
RUN cmake -G Ninja /opt/src/wireshark \
    -D QT5=OFF \
    -D QT6=ON \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="${INSTALLDIR}/wireshark" \
    -D CMAKE_PREFIX_PATH="${INSTALLDIR}/openssl;${INSTALLDIR}/liboqs" \
    -D CMAKE_INSTALL_RPATH="${INSTALLDIR}/openssl/lib:${INSTALLDIR}/liboqs/lib" && \
    ninja -j"$(nproc)" && ninja install

# Test integration of OQS provider with OpenSSL
WORKDIR /opt/src/oqs-provider
ENV OPENSSL_CONF=${INSTALLDIR}/ssl/openssl.cnf
ENV OPENSSL_MODULES=${INSTALLDIR}/openssl/lib/ossl-modules
RUN mkdir -p _build
RUN ./scripts/runtests.sh -j"$(nproc)"

# Stage 2: Runtime - Create a lightweight image with essential binaries and configurations
FROM ubuntu:${UBUNTU_VERSION} AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ARG INSTALLDIR

# Install essential runtime tools and libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libc-ares2 pcaputils libssh-4 libgcrypt20 \
    libglib2.0-0 libpcap0.8 libspeexdsp1 zlib1g \
    libqt6core6 libqt6gui6 libqt6widgets6 libqt6printsupport6 \
    libqt6core5compat6 libqt6dbus6 libqt6multimedia6 libgpg-error0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="${INSTALLDIR}/wireshark/bin:${INSTALLDIR}/openssl/bin:${PATH}"
ENV OPENSSL_CONF=${INSTALLDIR}/ssl/openssl.cnf
ENV OPENSSL_MODULES=${INSTALLDIR}/openssl/lib/ossl-modules
ENV QT_QPA_PLATFORM=xcb
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

# Copy essential files from build stage
COPY --from=build ${INSTALLDIR}/wireshark ${INSTALLDIR}/wireshark
COPY --from=build ${INSTALLDIR}/openssl ${INSTALLDIR}/openssl
COPY --from=build ${INSTALLDIR}/liboqs ${INSTALLDIR}/liboqs
COPY --from=build ${INSTALLDIR}/ssl ${INSTALLDIR}/ssl

# Ensure runtime directory exists with correct permissions
RUN mkdir -p ${XDG_RUNTIME_DIR} && chmod 0700 ${XDG_RUNTIME_DIR}

CMD ["sh", "-c", "wireshark"]