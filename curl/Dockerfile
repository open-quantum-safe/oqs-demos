# Multi-stage build: First the full builder image:

 # Define version tags
ARG ALPINE_VERSION=3.20
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.11.0
ARG OQSPROVIDER_TAG=0.7.0
ARG CURL_VERSION=8.11.0

# Set the installation directory
ARG INSTALLDIR=/opt/oqssa

# Sets default signature and KEM algorithms.
# It can be set to any algorithm listed at https://github.com/open-quantum-safe/oqs-provider#algorithms
ARG SIG_ALG="dilithium3"
ARG DEFAULT_GROUPS="x25519:x448:kyber512:p256_kyber512:kyber768:p384_kyber768:kyber1024:p521_kyber1024"


FROM alpine:${ALPINE_VERSION} AS intermediate
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG CURL_VERSION
ARG INSTALLDIR
ARG SIG_ALG
ARG DEFAULT_GROUPS

LABEL version="5"

# Install necessary build tools and dependencies
RUN apk --no-cache add build-base linux-headers \
            libtool automake autoconf cmake \
            ninja make openssl openssl-dev \
            git wget

# Download all sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    wget https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz && tar -zxvf curl-${CURL_VERSION}.tar.gz;

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" .. \
          -DOQS_DIST_BUILD=ON \
          -DCMAKE_INSTALL_PREFIX="${INSTALLDIR}" && \
    ninja install

# Build OpenSSL and configure symbolic links.
WORKDIR /opt/openssl
RUN if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi && \
    LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix="${INSTALLDIR}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs;

# Set path for custom OpenSSL binary.
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build, install, and activate oqs-provider
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR="${INSTALLDIR}" \
          -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_PREFIX_PATH="${INSTALLDIR}" \
          -S . -B _build && \
    cmake --build _build && \
    cp _build/lib/oqsprovider.so "${INSTALLDIR}/lib64/ossl-modules" && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/\# Use this in order to automatically load providers/\# Set default KEM groups if not set via environment variable\nKDEFAULT_GROUPS = $DEFAULT_GROUPS\n\n# Use this in order to automatically load providers/g" ${INSTALLDIR}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${INSTALLDIR}/ssl/openssl.cnf

# Generate certificates for testing.
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

# build curl - injecting OQS CA generated above into root store
WORKDIR /opt/curl-${CURL_VERSION}

# Download and integrate LetsEncrypt Root CA to CA bundle
RUN wget https://letsencrypt.org/certs/isrgrootx1.pem -O oqs-bundle.pem && \
    cat ${INSTALLDIR}/bin/CA.crt >> oqs-bundle.pem

# Add --enable-debug to the configure command to enable curl debugging.
RUN env LDFLAGS="-Wl,-R${INSTALLDIR}/lib64" \
        ./configure --prefix="${INSTALLDIR}" \
                    --with-ca-bundle="${INSTALLDIR}/oqs-bundle.pem" \
                    --with-ssl="${INSTALLDIR}" \
                    --without-libpsl && \
    make -j"$(nproc)" && make install  \
    && mv oqs-bundle.pem "${INSTALLDIR}";

# Download current test.openquantumsafe.org test CA cert
WORKDIR ${INSTALLDIR}
RUN wget https://test.openquantumsafe.org/CA.crt && \
    mv CA.crt oqs-testca.pem

# Second stage: Minimal runtime image
FROM alpine:${ALPINE_VERSION} AS dev
ARG INSTALLDIR
ARG SIG_ALG

# Copy runtime files and configure environment for OpenSSL and Curl
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}
ENV PATH="${INSTALLDIR}/bin:${PATH}"
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

# Generate server certificates
WORKDIR ${INSTALLDIR}/bin
RUN set -x && \
    mkdir /opt/test && \
    ${OPENSSL} req -new -newkey ${SIG_ALG} \
        -keyout /opt/test/server.key -out /opt/test/server.csr \
        -nodes -subj "/CN=localhost" -config ${OPENSSL_CNF} && \
    ${OPENSSL} x509 -req \
        -in /opt/test/server.csr -out /opt/test/server.crt \
        -CA CA.crt -CAkey CA.key -CAcreateserial -days 365

# Optimize image size further
FROM dev
ARG INSTALLDIR

COPY serverstart.sh ${INSTALLDIR}/bin
COPY perftest.sh ${INSTALLDIR}/bin

# Remove unused libraries to optimize image.
RUN rm ${INSTALLDIR}/lib64/liboqs*

# Create user for runtime operations
RUN addgroup -g 1000 -S oqs && \
    adduser --uid 1000 -S oqs -G oqs && \
    chown -R oqs:oqs /opt/test && \
    chmod go+r ${INSTALLDIR}/bin/CA.key && \
    chmod go+w ${INSTALLDIR}/bin/CA.srl

USER oqs
CMD ["serverstart.sh"]
STOPSIGNAL SIGTERM