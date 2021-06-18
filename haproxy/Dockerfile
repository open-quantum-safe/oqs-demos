# Multi-stage build: First the full builder image:

# First: global build arguments: 

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

ARG BUILDDIR=/root

# installation paths
ARG INSTALLPATH=/opt/oqssa
ARG HAPROXY_PATH=/opt/haproxy

# defines the QSC signature algorithm used for the certificates:
ARG SIG_ALG="dilithium3"

# define the haproxy version to include
ARG HAPROXY_VERSION=2.2.6

# Pass parameters to `make`. Most notably set parallelism (`-j` [degree]) 
# only if you know your machine can handle it 
ARG MAKE_DEFINES=""


FROM alpine:3.11 as intermediate

# Take in global args
ARG INSTALLPATH
ARG BUILDDIR
ARG LIBOQS_BUILD_DEFINES
ARG HAPROXY_PATH
ARG SIG_ALG
ARG HAPROXY_VERSION
ARG MAKE_DEFINES


# Get all software packages required for builing all components:
# All SW-build and docker-image build prereqs
RUN apk update && apk upgrade && apk add openssl make build-base linux-headers openssl-dev autoconf automake git libtool unzip wget cmake 

# get sources
WORKDIR ${BUILDDIR}
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl && \
    wget http://www.haproxy.org/download/2.2/src/haproxy-${HAPROXY_VERSION}.tar.gz && tar xzvf haproxy-${HAPROXY_VERSION}.tar.gz && mv haproxy-${HAPROXY_VERSION} haproxy

# build liboqs (dynamic linking only)
WORKDIR ${BUILDDIR}/liboqs
RUN mkdir build && cd build && if [[ -z "$MAKE_DEFINES" ]] ; then nproc=$(getconf _NPROCESSORS_ONLN) && MAKE_DEFINES="-j $nproc"; fi && cmake .. ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${BUILDDIR}/openssl/oqs && make $MAKE_DEFINES && make install

# build OQS-OpenSSL (again, dynamic/shared libs only)
WORKDIR ${BUILDDIR}/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,$INSTALLPATH/lib" ./Configure linux-x86_64 -lm --prefix=$INSTALLPATH && if [[ -z "$MAKE_DEFINES" ]] ; then nproc=$(getconf _NPROCESSORS_ONLN) && MAKE_DEFINES="-j $nproc"; fi && make $MAKE_DEFINES && make install_sw

# build haproxy
WORKDIR ${BUILDDIR}/haproxy

RUN if [[ -z "$MAKE_DEFINES" ]] ; then nproc=$(getconf _NPROCESSORS_ONLN) && MAKE_DEFINES="-j $nproc"; fi && make $MAKE_DEFINES LDFLAGS="-Wl,-rpath,$INSTALLPATH/lib" SSL_INC=$INSTALLPATH/include SSL_LIB=$INSTALLPATH/lib TARGET=linux-musl USE_OPENSSL=1 && make PREFIX=$INSTALLPATH install

#
# prepare to run haproxy
ARG OPENSSL_CNF=${BUILDDIR}/openssl/apps/openssl.cnf

# Set a default QSC signature algorithm from the list at https://github.com/open-quantum-safe/openssl#authentication
ARG SIG_ALG=dilithium3

WORKDIR ${HAPROXY_PATH}
    # generate CA key and cert
    # generate server CSR
    # generate server cert
RUN set -x && \
    mkdir pki && \
    mkdir cacert && \
    ${INSTALLPATH}/bin/openssl req -x509 -new -newkey ${SIG_ALG} -keyout cacert/CA.key -out cacert/CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    ${INSTALLPATH}/bin/openssl req -new -newkey ${SIG_ALG} -keyout pki/server.key -out pki/server.csr -nodes -subj "/CN=oqs-haproxy" -config ${OPENSSL_CNF} && \
    ${INSTALLPATH}/bin/openssl x509 -req -in pki/server.csr -out pki/server.crt -CA cacert/CA.crt -CAkey cacert/CA.key -CAcreateserial -days 365

# second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:3.11
# Take in global args
ARG HAPROXY_PATH
ARG INSTALLPATH

# lighttpd as built-in backend
RUN apk add lighttpd
#
# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${HAPROXY_PATH} ${HAPROXY_PATH}
COPY --from=intermediate ${INSTALLPATH} ${INSTALLPATH}

COPY conf ${HAPROXY_PATH}/conf/
WORKDIR ${HAPROXY_PATH}

ADD lighttpd.conf /etc/lighttpd/lighttpd.conf
ADD lighttpd2.conf /etc/lighttpd/lighttpd2.conf
ADD start.sh ${HAPROXY_PATH}/start.sh

# set up normal user
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${HAPROXY_PATH}

# set up file permissions for lighttpd
RUN mkdir -p /opt/lighttpd/log && mkdir -p /opt/lighttpd/log2 && chown -R oqs.oqs /opt

# set up demo backend using lighttpd:
RUN echo "Hello World from lighthttpd backend #1. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost/htdocs/index.html
RUN mkdir -p /var/www/localhost2/htdocs && echo "Hello World from lighthttpd backend #2. If you see this, all is fine: lighttpd data served via haproxy protected by OQSSL..." > /var/www/localhost2/htdocs/index.html

USER oqs

# Ensure haproxy just runs
ENV PATH ${HAPROXY_PATH}/sbin:$PATH

EXPOSE 4433
#
STOPSIGNAL SIGTERM

CMD ["/opt/haproxy/start.sh"]

