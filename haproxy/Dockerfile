# Multi-stage build: First the full builder image:

# define the alpine image version to use
ARG ALPINE_VERSION=3.20

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.3.2

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.11.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.7.0

# define the version of haproxy here
ARG HAPROXY_RELEASE=3.0
ARG HAPROXY_MICRO=5
ARG HAPROXY_VERSION=${HAPROXY_RELEASE}.${HAPROXY_MICRO}

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa
ARG HAPROXYDIR=/opt/haproxy

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Default KEM algorithms to be utilized
ARG KEM_ALGLIST="kyber768:p384_kyber768"

FROM alpine:${ALPINE_VERSION} AS intermediate
# Take in all global args
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG HAPROXYDIR
ARG LIBOQS_BUILD_DEFINES
ARG KEM_ALGLIST
ARG HAPROXY_VERSION
ARG HAPROXY_RELEASE

LABEL version "2"

ENV DEBIAN_FRONTEND noninteractive

# Get all software packages required for builing all components:
RUN apk update && apk upgrade && apk add openssl make build-base linux-headers openssl-dev autoconf automake git libtool unzip wget cmake ninja

# get all sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    wget http://www.haproxy.org/download/${HAPROXY_RELEASE}/src/haproxy-${HAPROXY_VERSION}.tar.gz && tar xzvf haproxy-${HAPROXY_VERSION}.tar.gz && mv haproxy-${HAPROXY_VERSION} $HAPROXYDIR

# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build && cd build && \
    cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && \
    ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix=${INSTALLDIR} && \
    make -j $(nproc) && \
    make install_sw install_ssldirs && \
    if [ -d ${INSTALLDIR}/lib64 ]; then ln -s ${INSTALLDIR}/lib64 ${INSTALLDIR}/lib; fi && \
    if [ -d ${INSTALLDIR}/lib ]; then ln -s ${INSTALLDIR}/lib ${INSTALLDIR}/lib64; fi

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf


ENV OPENSSL3_DIR=${INSTALLDIR}

# build haproxy
WORKDIR ${HAPROXYDIR}

RUN make -j $(nproc) \
    LDFLAGS="-Wl,-rpath,$INSTALLDIR/lib64" \
    SSL_INC=$INSTALLDIR/include \
    SSL_LIB=$INSTALLDIR/lib64 \
    TARGET=linux-musl \
    USE_OPENSSL=1 && \
    make PREFIX=$INSTALLDIR install

# prepare to run haproxy
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

# Set a default QSC signature algorithm from the list at https://github.com/open-quantum-safe/oqs-provider#algorithms
ARG SIG_ALG=dilithium3

WORKDIR ${HAPROXYDIR}
    # generate CA key and cert
    # generate server CSR
    # generate server cert
RUN set -x && \
    mkdir pki && \
    mkdir cacert && \
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout cacert/CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout pki/server.key -out pki/server.csr -nodes -subj "/CN=oqs-haproxy" -config ${OPENSSL_CNF} && \
    ${OPENSSL} x509 -req -in pki/server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey cacert/CA.key -CAcreateserial -days 365

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:${ALPINE_VERSION}
# Take in all global args
ARG INSTALLDIR
ARG HAPROXYDIR
ARG KEM_ALGLIST

# lighttpd as built-in backend
RUN apk add lighttpd
#
# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${HAPROXYDIR} ${HAPROXYDIR}
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# copy the haproxy configuration file and set the supported Key exchange mechanisms
COPY conf ${HAPROXYDIR}/conf/
RUN sed -i "s|@@CURVES@@|$KEM_ALGLIST|g" ${HAPROXYDIR}/conf/haproxy.cfg

WORKDIR ${HAPROXYDIR}

ADD lighttpd.conf /etc/lighttpd/lighttpd.conf
ADD lighttpd2.conf /etc/lighttpd/lighttpd2.conf
ADD start.sh ${HAPROXYDIR}/start.sh

# set up normal user
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${HAPROXYDIR}

# set up file permissions for lighttpd
RUN mkdir -p /opt/lighttpd/log && mkdir -p /opt/lighttpd/log2 && chown -R oqs.oqs /opt

# set up demo backend using lighttpd:
RUN echo "Hello World from lighthttpd backend #1. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost/htdocs/index.html
RUN mkdir -p /var/www/localhost2/htdocs && echo "Hello World from lighthttpd backend #2. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost2/htdocs/index.html

USER oqs

# Ensure haproxy just runs
ENV PATH ${HAPROXYDIR}/sbin:$PATH

EXPOSE 4433

STOPSIGNAL SIGTERM

CMD ["/opt/haproxy/start.sh"]
