# Define build arguments for version tags, installation paths, and configurations
ARG ALPINE_VERSION=3.21
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0
ARG HTTPD_VERSION=2.4.63
ARG APR_VERSION=1.7.6
ARG APRU_VERSION=1.6.3
ARG OPENSSL_PATH=/opt/openssl
ARG HTTPD_PATH=/opt/httpd
ARG APR_MIRROR="https://dlcdn.apache.org"

# Specify supported signature and key encapsulation mechanisms (KEM) algorithms
ARG SIG_ALG="mldsa65"
ARG DEFAULT_GROUPS="mlkem768:p384_mlkem768"

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM alpine:${ALPINE_VERSION} AS intermediate
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG OPENSSL_PATH
ARG HTTPD_PATH
ARG SIG_ALG
ARG HTTPD_VERSION
ARG APR_VERSION
ARG APRU_VERSION
ARG APR_MIRROR
ARG DEFAULT_GROUPS

# Install required build tools and system dependencies
RUN apk update && apk --no-cache add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make git wget pcre-dev expat-dev

# Download and prepare source files needed for the build process
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl ossl-src && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider && \
    wget ${APR_MIRROR}/apr/apr-${APR_VERSION}.tar.gz && tar xzvf apr-${APR_VERSION}.tar.gz && \
    wget ${APR_MIRROR}/apr/apr-util-${APRU_VERSION}.tar.gz && tar xzvf apr-util-${APRU_VERSION}.tar.gz && \
    wget --trust-server-names "https://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.gz" && tar -zxvf httpd-${HTTPD_VERSION}.tar.gz;

# Build and install OpenSSL
WORKDIR /opt/ossl-src
RUN LDFLAGS="-Wl,-rpath -Wl,${OPENSSL_PATH}/lib64" ./config no-shared --prefix="${OPENSSL_PATH}" && \
    make -j"$(nproc)" && make install_sw install_ssldirs && \
    if [ -d "${OPENSSL_PATH}/lib64" ]; then ln -s "${OPENSSL_PATH}/lib64" "${OPENSSL_PATH}/lib"; fi && \
    if [ -d "${OPENSSL_PATH}/lib" ]; then ln -s "${OPENSSL_PATH}/lib" "${OPENSSL_PATH}/lib64"; fi

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" ..  \
    -DOQS_DIST_BUILD=ON -DBUILD_SHARED_LIBS=ON  \
    -DCMAKE_INSTALL_PREFIX=${OPENSSL_PATH} && \
    ninja && ninja install

# Build, install, and configure the oqs-provider for OpenSSL integration
WORKDIR /opt/oqs-provider
RUN cmake -DOPENSSL_ROOT_DIR="${OPENSSL_PATH}" -DCMAKE_PREFIX_PATH="${OPENSSL_PATH}" -S . -B build && \
    cmake --build build && \
    MODULESDIR="$(find "${OPENSSL_PATH}" -name ossl-modules)" && \
    cp build/lib/oqsprovider.so "${MODULESDIR}/oqsprovider.so" && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${OPENSSL_PATH}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${OPENSSL_PATH}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${OPENSSL_PATH}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${OPENSSL_PATH}/ssl/openssl.cnf

# Build and install httpd
WORKDIR /opt
RUN sed -i "s/\$RM \"\$cfgfile\"/\$RM -f \"\$cfgfile\"/g" "apr-${APR_VERSION}/configure" && \
    ./apr-${APR_VERSION}/configure && make -j"$(nproc)" && make install

WORKDIR /opt/apr-util-${APRU_VERSION}
RUN ./configure x86_64-pc-linux-gnu --with-crypto --with-openssl="${OPENSSL_PATH}" --with-apr="/usr/local/apr" && \
    make -j"$(nproc)" && make install

WORKDIR /opt/httpd-${HTTPD_VERSION}
RUN ./configure --prefix="${HTTPD_PATH}" \
                    --enable-debugger-mode \
                    --enable-ssl --with-ssl="${OPENSSL_PATH}" \
                    --enable-ssl-staticlib-deps \
                    --enable-mods-static=ssl && \
    make -j"$(nproc)" && make install;

# prepare to run httpd
ARG OPENSSL_CNF=${OPENSSL_PATH}/ssl/openssl.cnf

WORKDIR ${HTTPD_PATH}

# Generate CA key and certificate, create server CSR, and issue server certificate
RUN set -x && \
    mkdir pki && \
    mkdir cacert && \
    ${OPENSSL_PATH}/bin/openssl req -x509 -new -newkey ${SIG_ALG} -keyout cacert/CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    ${OPENSSL_PATH}/bin/openssl req -new -newkey ${SIG_ALG} -keyout pki/server.key -out pki/server.csr -nodes -subj "/CN=oqs-httpd" -config ${OPENSSL_CNF} && \
    ${OPENSSL_PATH}/bin/openssl x509 -req -in pki/server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey cacert/CA.key -CAcreateserial -days 365

# Stage 2: Runtime - Lightweight image with essential binaries and configurations
FROM alpine:${ALPINE_VERSION}
ARG HTTPD_PATH
ARG OPENSSL_PATH

# Install runtime tools and dependencies
RUN apk update && apk --no-cache add pcre-dev expat-dev

# Copy necessary components from the build stage
COPY --from=intermediate ${HTTPD_PATH} ${HTTPD_PATH}
COPY --from=intermediate /usr/local/apr/lib /usr/local/apr/lib
COPY --from=intermediate ${OPENSSL_PATH}/ssl ${OPENSSL_PATH}/ssl
COPY --from=intermediate ${OPENSSL_PATH}/lib64 ${OPENSSL_PATH}/lib64

# Create symbolic links for OpenSSL library paths
RUN ln -s ${OPENSSL_PATH}/lib64 ${OPENSSL_PATH}/lib

# Copy HTTPD configuration files
COPY httpd-conf/httpd-ssl.conf ${HTTPD_PATH}/httpd-conf/httpd-ssl.conf
COPY httpd-conf/httpd.conf ${HTTPD_PATH}/httpd-conf/httpd.conf

# Configure log forwarding
WORKDIR ${HTTPD_PATH}
RUN ln -sf /dev/stdout ${HTTPD_PATH}/logs/access_log && \
    ln -sf /dev/stderr ${HTTPD_PATH}/logs/error_log

# Set up non-root user for improved security, adjust ownership
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && \
    chown -R oqs:oqs ${HTTPD_PATH}

# Switch to the non-root user
USER oqs

# Set PATH to include HTTPD binaries for runtime execution
ENV PATH="${HTTPD_PATH}/bin:$PATH"

# Expose port for secure communication
EXPOSE 4433

# Specify stop signal and startup command for HTTPD
STOPSIGNAL SIGTERM
CMD ["httpd", "-f", "httpd-conf/httpd.conf", "-D", "FOREGROUND"]