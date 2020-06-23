# Multi-stage build: First the full builder image:

# First: global build arguments: 

# liboqs build type variant; build non-optimized by default (maximum portability of image):
ARG LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF"

# installation paths
ARG OPENSSL_PATH=/opt/openssl
ARG NGINX_PATH=/opt/nginx

# defines the QSC signature algorithm used for the certificates:
ARG SIG_ALG="dilithium3"

# define the nginx version to include
ARG NGINX_VERSION=1.16.1

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 2"


FROM alpine as intermediate
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG NGINX_PATH
ARG SIG_ALG
ARG NGINX_VERSION
ARG MAKE_DEFINES


# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake \
            make \
            openssl openssl-dev \
            git wget pcre-dev

# get OQS sources
WORKDIR /opt
RUN git clone --depth 1 --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl && \
    wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs (static only)
WORKDIR /opt/liboqs
RUN mkdir build-static && cd build-static && cmake ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=${OPENSSL_PATH}/oqs .. && make ${MAKE_DEFINES} && make install

# build nginx (which builds OQS-OpenSSL)
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure --prefix=${NGINX_PATH} \
                --with-debug \
                --with-http_ssl_module --with-openssl=${OPENSSL_PATH} \
                --without-http_gzip_module \
                --with-cc-opt=-I${OPENSSL_PATH}/oqs/include \
                --with-ld-opt="-L${OPENSSL_PATH}/oqs/lib" && \
    sed -i 's/libcrypto.a/libcrypto.a -loqs/g' objs/Makefile && \
    make ${MAKE_DEFINES} && make install;

WORKDIR ${NGINX_PATH}

    # generate CA key and cert
    # generate server CSR
    # generate server cert
RUN set -x && \
    mkdir cacert && \
    mkdir pki && \
    ${OPENSSL_PATH}/apps/openssl req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_PATH}/apps/openssl.cnf && \
    ${OPENSSL_PATH}/apps/openssl req -new -newkey ${SIG_ALG} -keyout pki/server.key -out server.csr -nodes -subj "/CN=oqs-nginx" -config ${OPENSSL_PATH}/apps/openssl.cnf && \
    ${OPENSSL_PATH}/apps/openssl x509 -req -in server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey CA.key -CAcreateserial -days 365

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine 
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG NGINX_PATH
ARG SIG_ALG

RUN apk add pcre-dev

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${NGINX_PATH} ${NGINX_PATH}
#COPY --from=intermediate ${OPENSSL_PATH}/apps/openssl ${OPENSSL_PATH}
COPY nginx-conf/ ${NGINX_PATH}/nginx-conf

WORKDIR ${NGINX_PATH}

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${NGINX_PATH}/logs/access.log && \
    ln -sf /dev/stderr ${NGINX_PATH}/logs/error.log;

# This expose command needs to be in line with what's spec'd in nginx.conf:
EXPOSE 4433

# Ensure nginx just runs
ENV PATH ${NGINX_PATH}/sbin:$PATH

STOPSIGNAL SIGTERM

# Enable a normal user to create new server keys off set CA
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${NGINX_PATH}
USER oqs

CMD ["nginx", "-c", "nginx-conf/nginx.conf", "-g", "daemon off;"]

