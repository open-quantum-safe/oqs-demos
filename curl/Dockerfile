# Multi-stage build: First the full builder image:

FROM alpine:3.11 as intermediate
LABEL version="1"

ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake \
            make \
            openssl openssl-dev \
            git docker wget

# define the Curl version to be baked in
ENV CURL_VERSION 7.69.1

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# liboqs build type variant
ARG LIBOQS_BUILD_DEFINES

# get all sources
WORKDIR /opt
RUN git clone --single-branch --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --single-branch --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl ossl-src && \
    wget https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz && tar -zxvf curl-${CURL_VERSION}.tar.gz;

# Add curl patchfile
ADD patch-7.69.1.oqs.txt /opt/patch-7.69.1.oqs.txt

# build liboqs shared and static
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake .. ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/opt/ossl-src/oqs && make && make install
RUN mkdir build-static && cd build-static && cmake .. -DCMAKE_BUILD_TYPE=${LIBOQS_BUILD_TYPE} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/opt/ossl-src/oqs && make && make install

# build OQS-OpenSSL
WORKDIR /opt/ossl-src
# curl looks for shared libraries
# at ./configure time
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib" ./config shared --prefix=${INSTALLDIR} && \
    make && make install;

# set path to use 'new' openssl & curl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# generate certificates for openssl s_server, which is what we will test curl against
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

# Default root CA signature algorithm; can be set to any listed at https://github.com/open-quantum-safe/openssl#authentication
ARG SIG_ALG="dilithium2"

WORKDIR ${INSTALLDIR}/bin
RUN set -x && \
    # generate CA key and cert
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} 

# build curl - injecting OQS CA generated above into root store
WORKDIR /opt/curl-${CURL_VERSION}
RUN patch -p1 < /opt/patch-7.69.1.oqs.txt

# For curl debugging enable it by adding the line below to the configure command:
#                    --enable-debug \

RUN env CPPFLAGS="-I/opt/ossl-src/oqs/include" \
        LDFLAGS=-Wl,-R${INSTALLDIR}/lib  \
        ./configure --prefix=${INSTALLDIR} \
                    --with-ca-bundle=${INSTALLDIR}/bin/CA.crt \
                    --with-ssl=${INSTALLDIR} && \
    make && make install;

WORKDIR /

COPY serverstart.sh ${INSTALLDIR}/bin

CMD ["serverstart.sh"]

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:3.11

# Default root CA signature algorithm; can be set to any listed at https://github.com/open-quantum-safe/openssl#authentication
ARG SIG_ALG="dilithium2"

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# Only retain the ${INSTALLDIR} contents in the final image
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# set path to use 'new' openssl & curl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# generate certificates for openssl s_server, which is what we will test curl against
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR}/bin

RUN set -x && mkdir /opt/test && \
    # generate server CSR using pre-set CA.key & cert
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" -config ${OPENSSL_CNF} && \
    # generate server cert
    ${OPENSSL} x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;
#
WORKDIR /

COPY serverstart.sh ${INSTALLDIR}/bin
COPY perftest.sh ${INSTALLDIR}/bin

# Enable a normal user to create new server keys off set CA
RUN addgroup -S oqs && adduser -S oqs -G oqs && chown -R oqs.oqs /opt/test && chmod go+r ${INSTALLDIR}/bin/CA.key && chmod go+w ${INSTALLDIR}/bin/CA.srl

USER oqs
CMD ["serverstart.sh"]
