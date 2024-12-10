# Multi-stage build: First the full builder image:

# First: global build arguments:

# define the alpine image version to use
ARG ALPINE_VERSION=3.20

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.3.2

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.11.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.7.0

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# base install path
ARG BASEDIR="/opt"

# installation paths
ARG INSTALLDIR=${BASEDIR}/nginx

# defines the QSC signature algorithm used for the certificates:
ARG SIG_ALG="dilithium3"

# defines the list of default groups to be activated in nginx-openssl config:
ARG DEFAULT_GROUPS=x25519:x448:kyber512:p256_kyber512:kyber768:p384_kyber768:kyber1024:p521_kyber1024

# define the nginx version to include
ARG NGINX_VERSION=1.27.2

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 18"


FROM alpine:${ALPINE_VERSION} AS intermediate
# Take in global args
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG BASEDIR
ARG LIBOQS_BUILD_DEFINES
ARG INSTALLDIR
ARG SIG_ALG
ARG NGINX_VERSION
ARG MAKE_DEFINES
ARG DEFAULT_GROUPS
ARG OSSLDIR=${BASEDIR}/openssl/.openssl


# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            openssl openssl-dev \
            git wget pcre-dev

# get OQS sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs (static only)
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -G"Ninja" ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} .. && ninja && ninja install

# build nginx (also building openssl)
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure --prefix=${INSTALLDIR} \
                --with-debug \
                --with-http_ssl_module --with-openssl=/opt/openssl \
                --without-http_gzip_module && \
    make ${MAKE_DEFINES} && make install;

# create openssl.cnf activating oqsprovider & setting default groups
RUN mkdir -p ${OSSLDIR=}/ssl && \
    cp /opt/openssl/apps/openssl.cnf ${OSSLDIR}/ssl/ && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${OSSLDIR}/ssl/openssl.cnf && \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${OSSLDIR}/ssl/openssl.cnf

# build oqsprovider
WORKDIR /opt/oqs-provider

RUN ln -s /opt/nginx/include/oqs ${OSSLDIR}/include && \
    rm -rf build && \
    cmake -DCMAKE_BUILD_TYPE=Debug -DOPENSSL_ROOT_DIR=${OSSLDIR} -DCMAKE_PREFIX_PATH=$INSTALLDIR -S . -B build && \
    cmake --build build && \
    export MODULESDIR=$(find ${OSSLDIR} -name ossl-modules) && \
    cp build/lib/oqsprovider.so $MODULESDIR && \
    mkdir -p ${OSSLDIR}/lib64 && \
    ln -s ${OSSLDIR}/lib/ossl-modules ${OSSLDIR}/lib64 && \
    rm -rf ${INSTALLDIR}/lib64

WORKDIR ${INSTALLDIR}

# Test/Utilize oqsprovider:
    # generate CA key and cert
    # generate server CSR
    # generate server cert

ENV PATH ${INSTALLDIR}/sbin:${OSSLDIR}/bin:$PATH
# begin optimizing sizes:
RUN strip ${OSSLDIR}/lib/*.a ${OSSLDIR}/lib64/ossl-modules/oqsprovider.so ${INSTALLDIR}/sbin/* ${INSTALLDIR}/sbin/*
RUN set -x && \
    mkdir cacert && \
    mkdir pki && \
    openssl req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OSSLDIR}/ssl/openssl.cnf && \
    openssl req -new -newkey ${SIG_ALG} -keyout pki/server.key -out server.csr -nodes -subj "/CN=oqs-nginx" -config ${OSSLDIR}/ssl/openssl.cnf && \
    openssl x509 -req -in server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey CA.key -CAcreateserial -days 365

# further optimize sizes:
RUN rm ${OSSLDIR}/bin/*

# second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:${ALPINE_VERSION}
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG INSTALLDIR
ARG SIG_ALG
ARG BASEDIR
ARG OSSLDIR=${BASEDIR}/openssl/.openssl

LABEL version="3"

RUN apk add pcre-dev

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}
COPY --from=intermediate ${OSSLDIR} ${OSSLDIR}
COPY nginx-conf/ ${INSTALLDIR}/nginx-conf

WORKDIR ${INSTALLDIR}

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${INSTALLDIR}/logs/access.log && \
    ln -sf /dev/stderr ${INSTALLDIR}/logs/error.log;

# This expose command needs to be in line with what's spec'd in nginx.conf:
EXPOSE 4433

# Ensure nginx just runs
ENV PATH ${INSTALLDIR}/sbin:$PATH

STOPSIGNAL SIGTERM

# Enable a normal user to create new server keys off set CA
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${INSTALLDIR}
USER oqs
# From nginx 1.25.2: "nginx does not try to load OpenSSL configuration if the --with-openssl option was used to built OpenSSL and the OPENSSL_CONF environment variable is not set".
# We therefore have to set the OPENSSL_CONF environment variable.
ENV OPENSSL_CONF ${OSSLDIR}/ssl/openssl.cnf
CMD ["nginx", "-c", "nginx-conf/nginx.conf", "-g", "daemon off;"]
