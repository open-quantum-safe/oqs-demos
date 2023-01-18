# Multi-stage build: First the full builder image:

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 2"

# Change this at your own risk: OSSL3 can handle OQS-sigs only
# after https://github.com/openssl/openssl/pull/19312 lands
ARG SIG_ALG="rsa:2048"

FROM alpine:3.13 as intermediate
# Take in all global args
ARG CURL_VERSION
ARG INSTALLDIR
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
ARG SIG_ALG

LABEL version="1"

ENV DEBIAN_FRONTEND noninteractive

RUN apk update && apk upgrade

# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            openssl openssl-dev \
            git docker wget

# get all sources
WORKDIR /opt
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch master https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch main https://github.com/open-quantum-safe/oqs-provider.git

WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix=${INSTALLDIR} && \
    make ${MAKE_DEFINES} && make install;

# set path to use 'new' openssl & curl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf

# generate certificates for openssl s_server, which is what we will test curl against
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR}/bin
# generate CA key and cert
RUN set -x; \
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF}

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:3.13 as dev
# Take in all global args
ARG INSTALLDIR
ARG SIG_ALG

# Only retain the ${INSTALLDIR} contents in the final image
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# generate certificates for openssl s_server, which is what we will test curl against
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR}/bin

# oqs-provider cannot deal with OQS sigs, so use classic crypto for sigs
# generate server CSR using pre-set CA.key and cert
# and generate server cert
RUN set -x && mkdir /opt/test; \
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" -config ${OPENSSL_CNF}; \
    ${OPENSSL} x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

COPY serverstart.sh ${INSTALLDIR}/bin

WORKDIR ${INSTALLDIR}

FROM dev
ARG INSTALLDIR

WORKDIR /

# Enable a normal user to create new server keys off set CA
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs /opt/test && chmod go+r ${INSTALLDIR}/bin/CA.key 

#USER oqs
CMD ["serverstart.sh"]
STOPSIGNAL SIGTERM
