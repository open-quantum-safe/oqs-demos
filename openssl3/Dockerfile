# Define build arguments for version tags, installation paths, and configurations
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.12.0
ARG OQSPROVIDER_TAG=0.8.0

ARG INSTALLDIR_OPENSSL=/opt/openssl
ARG INSTALLDIR_LIBOQS=/opt/liboqs

ARG SIG_ALG="dilithium3"

# Stage 1: Build OpenSSL
FROM alpine:${ALPINE_VERSION} AS buildopenssl
ARG OPENSSL_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG SIG_ALG

LABEL version="3"

RUN apk --no-cache add build-base linux-headers \
            libtool automake autoconf make git wget

WORKDIR /optbuild
RUN git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git

# Configure, compile, and install OpenSSL
WORKDIR /optbuild/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR_OPENSSL}/lib64" \
    ./config shared --prefix=${INSTALLDIR_OPENSSL} && \
    make -j"$(nproc)" && make install && \
    if [ -d ${INSTALLDIR_OPENSSL}/lib64 ]; then ln -s ${INSTALLDIR_OPENSSL}/lib64 ${INSTALLDIR_OPENSSL}/lib; fi && \
    if [ -d ${INSTALLDIR_OPENSSL}/lib ]; then ln -s ${INSTALLDIR_OPENSSL}/lib ${INSTALLDIR_OPENSSL}/lib64; fi

# Stage 2: Build liboqs
FROM alpine:${ALPINE_VERSION} AS buildliboqs
ARG LIBOQS_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG SIG_ALG

LABEL version="3"

RUN apk --no-cache add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make git wget

# Copy the OpenSSL installation from the previous stage
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

WORKDIR /optbuild
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs

# Configure and compile liboqs using the Ninja build system
WORKDIR /optbuild/liboqs/build
RUN cmake -G"Ninja" ..  \
    -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR_LIBOQS} && \
    ninja install

# Stage 3: Build oqs-provider
FROM alpine:${ALPINE_VERSION} AS buildoqsprovider
ARG OQSPROVIDER_TAG
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG SIG_ALG

LABEL version="3"

RUN apk --no-cache add build-base linux-headers \
            libtool cmake ninja git wget

WORKDIR /optbuild
RUN git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git

# Copy previously built OpenSSL and liboqs installations
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}
COPY --from=buildliboqs ${INSTALLDIR_LIBOQS} ${INSTALLDIR_LIBOQS}

# Build, install, and configure the oqs-provider
WORKDIR /optbuild/oqs-provider
RUN liboqs_DIR=${INSTALLDIR_LIBOQS} cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR_OPENSSL} -S . -B _build && \
    cmake --build _build && \
    cmake --install _build && \
    cp _build/lib/oqsprovider.so ${INSTALLDIR_OPENSSL}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME           = .\nDEFAULT_GROUPS = kyber768/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf

# Update PATH to include the newly installed OpenSSL binaries
WORKDIR ${INSTALLDIR_OPENSSL}/bin
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"

# Generate a Certificate Authority (CA) key and certificate
RUN set -x; \
    openssl req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365

# Stage 4: Create Minimal Runtime Image
FROM alpine:${ALPINE_VERSION} AS dev
ARG INSTALLDIR_OPENSSL
ARG SIG_ALG

# Retain only the OpenSSL installation for the final image
COPY --from=buildoqsprovider ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

# Ensure the PATH uses the newly built OpenSSL binaries
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"

# Set working directory to the OpenSSL binary directory for certificate generation
WORKDIR ${INSTALLDIR_OPENSSL}/bin

# Create test directories and generate server certificate signing requests (CSR)
# and server certificates using the pre-generated CA key and certificate
RUN set -x && mkdir -p /opt/test; \
    openssl version && openssl list -providers && \
    openssl req -new -newkey ${SIG_ALG} -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" && \
    openssl x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

# Copy the server startup script into the OpenSSL binary directory
COPY serverstart.sh ${INSTALLDIR_OPENSSL}/bin

# Change working directory to the OpenSSL installation root
WORKDIR ${INSTALLDIR_OPENSSL}

# Stage 5: Final Image Configuration
FROM dev
ARG INSTALLDIR_OPENSSL

WORKDIR /

# Create a non-root user and group to allow key generation using the preset CA
RUN addgroup -g 1000 -S oqs && \
    adduser --uid 1000 -S oqs -G oqs && \
    chown -R oqs:oqs /opt/test && \
    chmod go+r ${INSTALLDIR_OPENSSL}/bin/CA.key

CMD ["/opt/openssl/bin/serverstart.sh"]
STOPSIGNAL SIGTERM