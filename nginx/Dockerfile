# Define build arguments for version tags, installation paths, and configurations
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0
ARG NGINX_VERSION=1.28.0
ARG BASEDIR="/opt"
ARG INSTALLDIR=${BASEDIR}/nginx

# Specify supported signature and key encapsulation mechanisms (KEM) algorithms
ARG SIG_ALG="mldsa65"
ARG DEFAULT_GROUPS=x25519:x448:prime256v1:secp384r1:secp521r1:mlkem512:mlkem768:mlkem1024:X25519MLKEM768:SecP256r1MLKEM768

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM alpine:${ALPINE_VERSION} AS intermediate
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG NGINX_VERSION
ARG BASEDIR
ARG INSTALLDIR
ARG SIG_ALG
ARG DEFAULT_GROUPS
ARG OSSLDIR=${BASEDIR}/openssl/.openssl

# Install required build tools and system dependencies
RUN apk update && apk --no-cache add \
    build-base linux-headers libtool \
    automake autoconf make cmake ninja \
    openssl openssl-dev git wget pcre-dev

# Download and prepare source files needed for the build process
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs \
    && git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git \
    && git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git \
    && wget -q nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -zxf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja"  \
    -DOQS_DIST_BUILD=ON  \
    -DBUILD_SHARED_LIBS=OFF  \
    -DCMAKE_INSTALL_PREFIX="${INSTALLDIR}" ..  \
    && ninja -j"$(nproc)" && ninja install

# Build and install Nginx with custom OpenSSL and SSL support
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure --prefix=${INSTALLDIR} \
    --with-debug --with-http_ssl_module  \
    --with-openssl=/opt/openssl --without-http_gzip_module && \
    make -j"$(nproc)" && make install

# Configure OpenSSL to support the oqs-provider
RUN mkdir -p ${OSSLDIR=}/ssl && \
    cp /opt/openssl/apps/openssl.cnf ${OSSLDIR}/ssl/ && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${OSSLDIR}/ssl/openssl.cnf

# Build and install OQS provider
WORKDIR /opt/oqs-provider
RUN ln -s "/opt/nginx/include/oqs" "${OSSLDIR}/include" && \
    rm -rf build && \
    cmake -DCMAKE_BUILD_TYPE=Debug \
          -DOPENSSL_ROOT_DIR="${OSSLDIR}" \
          -DCMAKE_PREFIX_PATH="${INSTALLDIR}" \
          -S . -B build && \
    cmake --build build && \
    MODULESDIR=$(find "${OSSLDIR}" -name ossl-modules) && \
    export MODULESDIR && \
    cp build/lib/oqsprovider.so "${MODULESDIR}" && \
    mkdir -p "${OSSLDIR}/lib64" && \
    ln -s "${OSSLDIR}/lib/ossl-modules" "${OSSLDIR}/lib64" && \
    rm -rf "${INSTALLDIR:?}/lib64"

# Minimize image size, generate CA/server certificates, then cleanup
WORKDIR ${INSTALLDIR}
ENV PATH="${INSTALLDIR}/sbin:${OSSLDIR}/bin:${PATH}"

RUN set -ex && \
    strip "${OSSLDIR}/lib/"*.a "${OSSLDIR}/lib64/ossl-modules/oqsprovider.so" "${INSTALLDIR}/sbin/"* "${INSTALLDIR}/sbin/"* && \
    mkdir -p cacert pki && \
    openssl req -x509 -new -newkey "${SIG_ALG}" -keyout CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config "${OSSLDIR}/ssl/openssl.cnf" && \
    openssl req -new -newkey "${SIG_ALG}" -keyout pki/server.key -out server.csr -nodes -subj "/CN=oqs-nginx" -config "${OSSLDIR}/ssl/openssl.cnf" && \
    openssl x509 -req -in server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey CA.key -CAcreateserial -days 365 && \
    rm -f "${OSSLDIR}/bin/"*

# Stage 2: Runtime - Create a lightweight image with essential binaries and configurations
FROM alpine:${ALPINE_VERSION}
ARG INSTALLDIR
ARG SIG_ALG
ARG BASEDIR
ARG OSSLDIR=${BASEDIR}/openssl/.openssl

# Install required build tools and system dependencies
RUN apk update && apk --no-cache add pcre-dev

# Copy compiled artifacts and configuration from the intermediate stage
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}
COPY --from=intermediate ${OSSLDIR} ${OSSLDIR}
COPY nginx-conf/ ${INSTALLDIR}/nginx-conf

# Link logs to Docker collector
RUN set -ex && \
    ln -sf /dev/stdout "${INSTALLDIR}/logs/access.log" && \
    ln -sf /dev/stderr "${INSTALLDIR}/logs/error.log"

# This expose command needs to be in line with what's specified in nginx.conf:
EXPOSE 4433

# From Nginx 1.25.2: "nginx does not try to load OpenSSL configuration if the
# --with-openssl option was used to build OpenSSL and the OPENSSL_CONF
# environment variable is not set." Hence we must explicitly set OPENSSL_CONF.
ENV PATH="${INSTALLDIR}/sbin:${PATH}" \
    OPENSSL_CONF="${OSSLDIR}/ssl/openssl.cnf"

# Create non-root user and update permissions
RUN addgroup -g 1000 -S oqs \
 && adduser --uid 1000 -S oqs -G oqs \
 && chown -R oqs:oqs "${INSTALLDIR}"

# Run as non-root user
USER oqs
STOPSIGNAL SIGTERM
CMD ["nginx", "-c", "nginx-conf/nginx.conf", "-g", "daemon off;"]
