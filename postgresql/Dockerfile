# Define build arguments for version tags, installation paths, and configurations
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0
ARG POSTGRESQL_VERSION=17.2
ARG INSTALLDIR=/opt/oqssa

# Specify supported signature and key encapsulation mechanisms (KEM) algorithms
ARG SIG_ALG="mldsa65"
ARG DEFAULT_GROUPS="x25519:x448:prime256v1:secp384r1:mlkem512:mlkem768:mlkem1024:X25519MLKEM768:SecP256r1MLKEM768"

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM alpine:${ALPINE_VERSION} AS intermediate
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG POSTGRESQL_VERSION
ARG INSTALLDIR
ARG SIG_ALG
ARG DEFAULT_GROUPS

LABEL version="1"

# Install required build tools and system dependencies
RUN apk update && apk --no-cache add \
    build-base linux-headers libtool \
    automake autoconf make cmake ninja \
    openssl openssl-dev git wget \
    perl readline-dev zlib-dev flex bison \
    libxml2-dev icu-dev

# Download and prepare source files needed for the build process
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    wget -q https://ftp.postgresql.org/pub/source/v${POSTGRESQL_VERSION}/postgresql-${POSTGRESQL_VERSION}.tar.bz2 && \
    tar -xjf postgresql-${POSTGRESQL_VERSION}.tar.bz2 && \
    rm postgresql-${POSTGRESQL_VERSION}.tar.bz2

# Build and install OpenSSL
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix="${INSTALLDIR}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" .. \
    -DOQS_DIST_BUILD=ON \
    -DCMAKE_INSTALL_PREFIX="${INSTALLDIR}" && \
    ninja install

# Set PATH for custom OpenSSL binary
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build, install, and configure the oqs-provider for OpenSSL integration
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR="${INSTALLDIR}" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_PREFIX_PATH="${INSTALLDIR}" \
          -S . -B _build && \
    cmake --build _build && \
    MODULESDIR=$(find "${INSTALLDIR}" -name ossl-modules) && \
    cp _build/lib/oqsprovider.so "${MODULESDIR}/oqsprovider.so" && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${INSTALLDIR}/ssl/openssl.cnf

# Generate certificates for testing
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

# Generate CA key and certificate
WORKDIR ${INSTALLDIR}/bin
RUN set -x; \
    "${OPENSSL}" req -x509 -new \
                     -newkey "${SIG_ALG}" -keyout CA.key \
                     -out CA.crt -nodes \
                     -subj "/CN=oqstest CA" -days 365 \
                     -config "${OPENSSL_CNF}"

# Generate server key and certificate for PostgreSQL
RUN set -x && \
    mkdir -p /opt/pqcerts && \
    "${OPENSSL}" req -new -newkey "${SIG_ALG}" \
        -keyout /opt/pqcerts/server.key -out /opt/pqcerts/server.csr \
        -nodes -subj "/CN=oqs-postgresql" -config "${OPENSSL_CNF}" && \
    "${OPENSSL}" x509 -req \
        -in /opt/pqcerts/server.csr -out /opt/pqcerts/server.crt \
        -CA CA.crt -CAkey CA.key -CAcreateserial -days 365 && \
    cp CA.crt /opt/pqcerts/CA.crt

# Build and install PostgreSQL linked against OQS-enabled OpenSSL
WORKDIR /opt/postgresql-${POSTGRESQL_VERSION}
RUN PKG_CONFIG_PATH="${INSTALLDIR}/lib64/pkgconfig" \
    CFLAGS="-I${INSTALLDIR}/include" \
    LDFLAGS="-L${INSTALLDIR}/lib64 -Wl,-rpath,${INSTALLDIR}/lib64" \
    ./configure --prefix=/opt/postgresql \
                --with-openssl \
                --with-includes="${INSTALLDIR}/include" \
                --with-libraries="${INSTALLDIR}/lib64" && \
    make -j"$(nproc)" && make install

# Stage 2: Runtime - Create a lightweight image with essential binaries and configurations
FROM alpine:${ALPINE_VERSION}
ARG INSTALLDIR
ARG SIG_ALG
ARG DEFAULT_GROUPS

# Install runtime dependencies
RUN apk update && apk --no-cache add \
    readline libxml2 icu-libs bash

# Copy compiled artifacts from the build stage
COPY --from=intermediate /opt/postgresql /opt/postgresql
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}
COPY --from=intermediate /opt/pqcerts /opt/pqcerts

# Set environment variables
ENV PATH="/opt/postgresql/bin:${INSTALLDIR}/bin:${PATH}" \
    PGDATA="/var/lib/postgresql/data" \
    OPENSSL_CONF="${INSTALLDIR}/ssl/openssl.cnf" \
    DEFAULT_GROUPS="${DEFAULT_GROUPS}" \
    LD_LIBRARY_PATH="${INSTALLDIR}/lib64"

# Create non-root user for PostgreSQL
RUN addgroup -g 1000 -S postgres && \
    adduser --uid 1000 -S postgres -G postgres && \
    mkdir -p "${PGDATA}" /run/postgresql /opt/pqcerts && \
    chown -R postgres:postgres "${PGDATA}" /run/postgresql /opt/pqcerts /opt/postgresql

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set correct permissions on certificates
RUN chown postgres:postgres /opt/pqcerts/server.key && \
    chmod 600 /opt/pqcerts/server.key && \
    chown postgres:postgres /opt/pqcerts/server.crt && \
    chmod 644 /opt/pqcerts/server.crt

EXPOSE 5432

USER postgres

STOPSIGNAL SIGTERM
CMD ["docker-entrypoint.sh"]
