# Multi-stage build: First the full builder image:

# First: global build arguments: 

# liboqs build type variant; build non-optimized by default (maximum portability of image):
ARG LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF"

# installation paths
ARG OPENSSL_PATH=/opt/openssl
ARG HTTPD_PATH=/opt/httpd

# defines the QSC signature algorithm used for the certificates:
ARG SIG_ALG="dilithium3"

# define the httpd version to include
ARG HTTPD_VERSION=2.4.43

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 2"


FROM debian:buster-slim as intermediate
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG HTTPD_PATH
ARG SIG_ALG
ARG HTTPD_VERSION
ARG MAKE_DEFINES


RUN apt-get update -qq \
    && apt-get install -y build-essential \
                          git \
                          # OQS
                          autoconf \
                          automake \
			  cmake \
                          libtool \
                          libssl-dev \
                          # httpd
                          libapr1-dev \
                          libaprutil1-dev \
                          libexpat1-dev \
                          libpcre3-dev \
                          # misc
                          wget;

# get sources
WORKDIR /opt
RUN git clone --depth 1 --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl ossl-src && \
    wget --trust-server-names "https://downloads.apache.org//httpd/httpd-${HTTPD_VERSION}.tar.gz" && tar -zxvf httpd-${HTTPD_VERSION}.tar.gz;

# build liboqs (static linking only)
WORKDIR /opt/liboqs
RUN mkdir build-static && cd build-static && cmake ..  -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/opt/ossl-src/oqs && make ${MAKE_DEFINES} && make install

# build OQS-OpenSSL
WORKDIR /opt/ossl-src
RUN ./config no-shared --prefix=${OPENSSL_PATH} && \
    make ${MAKE_DEFINES} && make install;

# build httpd
WORKDIR /opt/httpd-${HTTPD_VERSION}
RUN sed -i 's,-lcrypto,-lcrypto /opt/ossl-src/oqs/lib/liboqs.a -ldl,g' configure && \
    env CPPFLAGS="-I/opt/ossl-src/oqs/include" \
        ./configure --prefix=${HTTPD_PATH} \
                    --enable-debugger-mode \
                    --enable-ssl --with-ssl=${OPENSSL_PATH} \
                    --enable-ssl-staticlib-deps \
                    --enable-mods-static=ssl && \
    # Append liboqs to the PROGRAM_LDADD variable definition in the generated Makefile
    sed -i 's,(LIBS),(LIBS) /opt/ossl-src/oqs/lib/liboqs.a,g' Makefile && \
    make ${MAKE_DEFINES} && make install;

# prepare to run httpd
ARG OPENSSL_CNF=${OPENSSL_PATH}/ssl/openssl.cnf

# Set a default QSC signature algorithm from the list at https://github.com/open-quantum-safe/openssl#authentication
ARG SIG_ALG=dilithium2

WORKDIR ${HTTPD_PATH}

    # generate CA key and cert
    # generate server CSR
    # generate server cert
RUN set -x && \
    mkdir pki && \
    mkdir cacert && \
    ${OPENSSL_PATH}/bin/openssl req -x509 -new -newkey ${SIG_ALG} -keyout cacert/CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    ${OPENSSL_PATH}/bin/openssl req -new -newkey ${SIG_ALG} -keyout pki/server.key -out pki/server.csr -nodes -subj "/CN=oqs-httpd" -config ${OPENSSL_CNF} && \
    ${OPENSSL_PATH}/bin/openssl x509 -req -in pki/server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey cacert/CA.key -CAcreateserial -days 365

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM debian:buster-slim 
# Take in global args
ARG HTTPD_PATH
ARG OPENSSL_PATH

RUN apt-get update -qq \
    && apt-get install -y libapr1-dev libaprutil1-dev

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${HTTPD_PATH} ${HTTPD_PATH}
#COPY --from=intermediate ${OPENSSL_PATH}/apps/openssl ${OPENSSL_PATH}

COPY httpd-conf/httpd-ssl.conf ${HTTPD_PATH}/httpd-conf/httpd-ssl.conf
COPY httpd-conf/httpd.conf ${HTTPD_PATH}/httpd-conf/httpd.conf
WORKDIR ${HTTPD_PATH}

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${HTTPD_PATH}/logs/access_log && \
    ln -sf /dev/stderr ${HTTPD_PATH}/logs/error_log;

RUN addgroup --gid 1000 oqs && useradd -u 1000 -g 1000 oqs
RUN chown -R oqs.oqs ${HTTPD_PATH}
USER oqs

# Ensure httpd just runs
ENV PATH ${HTTPD_PATH}/bin:$PATH

EXPOSE 4433

STOPSIGNAL SIGTERM

CMD ["httpd", "-f", "httpd-conf/httpd.conf", "-DFOREGROUND"]
