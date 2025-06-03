# Define build arguments for version tags, installation paths, and configurations.
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0
ARG HAPROXY_RELEASE=3.0
ARG HAPROXY_MICRO=5
ARG HAPROXY_VERSION=${HAPROXY_RELEASE}.${HAPROXY_MICRO}
ARG INSTALLDIR=/opt/oqssa
ARG HAPROXYDIR=/opt/haproxy

# Specify supported signature and key encapsulation mechanisms (KEM) algorithms.
ARG KEM_ALGLIST="mlkem768:p384_mlkem768"
ARG SIG_ALG=mldsa65

# Stage 1: Build - Compile and assemble all necessary components and dependencies.
FROM alpine:${ALPINE_VERSION} AS intermediate
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG HAPROXYDIR
ARG LIBOQS_BUILD_DEFINES
ARG KEM_ALGLIST
ARG SIG_ALG
ARG HAPROXY_VERSION
ARG HAPROXY_RELEASE

LABEL version="2"

# Install required build tools and system dependencies.
RUN apk update && apk --no-cache add openssl make  \
    build-base linux-headers openssl-dev \
    autoconf automake git libtool \
    unzip wget cmake ninja

# Download and prepare source files needed for the build process.
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    wget http://www.haproxy.org/download/${HAPROXY_RELEASE}/src/haproxy-${HAPROXY_VERSION}.tar.gz && \
    tar xzvf haproxy-${HAPROXY_VERSION}.tar.gz && \
    mv haproxy-${HAPROXY_VERSION} $HAPROXYDIR

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" ..  -DOQS_DIST_BUILD=ON -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && \
    ninja install

# build and install OpenSSL
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix="${INSTALLDIR}" && \
    make -j "$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${INSTALLDIR}/lib64" ]; then ln -s "${INSTALLDIR}/lib64" "${INSTALLDIR}/lib"; fi && \
    if [ -d "${INSTALLDIR}/lib" ]; then ln -s "${INSTALLDIR}/lib" "${INSTALLDIR}/lib64"; fi

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build, install, and configure the oqs-provider for OpenSSL integration.
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf

# Build and install haproxy
WORKDIR ${HAPROXYDIR}
RUN make -j "$(nproc)" \
    LDFLAGS="-Wl,-rpath,${INSTALLDIR}/lib64" \
    SSL_INC="${INSTALLDIR}/include" \
    SSL_LIB="${INSTALLDIR}/lib64" \
    TARGET="linux-musl" \
    USE_OPENSSL=1 && \
    make PREFIX="${INSTALLDIR}" install

# Prepare to run haproxy
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

# Generate CA key and certificate, server CSR, and server certificate
WORKDIR ${HAPROXYDIR}
RUN set -x && \
    mkdir pki && \
    mkdir cacert && \
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout cacert/CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout pki/server.key -out pki/server.csr -nodes -subj "/CN=oqs-haproxy" -config ${OPENSSL_CNF} && \
    ${OPENSSL} x509 -req -in pki/server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey cacert/CA.key -CAcreateserial -days 365

# Stage 2: Runtime - Create a lightweight image with essential binaries and configurations.
FROM alpine:${ALPINE_VERSION}
ARG INSTALLDIR
ARG HAPROXYDIR
ARG KEM_ALGLIST

# Install essential runtime tools and libraries.
RUN apk update && apk --no-cache add lighttpd

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${HAPROXYDIR} ${HAPROXYDIR}
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# Copy the haproxy configuration file and set the supported Key exchange mechanisms
COPY conf ${HAPROXYDIR}/conf/
RUN sed -i "s|@@CURVES@@|$KEM_ALGLIST|g" ${HAPROXYDIR}/conf/haproxy.cfg

WORKDIR ${HAPROXYDIR}
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf
COPY lighttpd2.conf /etc/lighttpd/lighttpd2.conf
COPY start.sh ${HAPROXYDIR}/start.sh

# Set up non-root user and configure permissions
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && \
    mkdir -p ${HAPROXYDIR} /opt/lighttpd/log /opt/lighttpd/log2 && \
    chown -R oqs:oqs ${HAPROXYDIR} /opt/lighttpd/log /opt/lighttpd/log2

# Configure demo backends using lighttpd
RUN mkdir -p /var/www/localhost/htdocs /var/www/localhost2/htdocs && \
    echo "Hello World from lighthttpd backend #1. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost/htdocs/index.html && \
    echo "Hello World from lighthttpd backend #2. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost2/htdocs/index.html

# Switch to non-root user and set up environment
USER oqs
ENV PATH=${HAPROXYDIR}/sbin:$PATH

# Expose ports and set entrypoint
EXPOSE 4433
STOPSIGNAL SIGTERM
CMD ["/opt/haproxy/start.sh"]