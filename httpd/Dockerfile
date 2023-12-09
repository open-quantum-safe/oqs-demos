# Multi-stage build: First the full builder image:

# First: global build arguments: 

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# installation paths
ARG OPENSSL_PATH=/opt/openssl
ARG HTTPD_PATH=/opt/httpd

# defines the QSC signature algorithm used for the certificates:
ARG SIG_ALG="dilithium3"

# defines default KEM groups to be announced
ARG DEFAULT_GROUPS="kyber768:p384_kyber768"

# define the httpd version to include
ARG HTTPD_VERSION=2.4.57

# define the APR version to include
ARG APR_VERSION=1.7.4

# define the APR util version to include
ARG APRU_VERSION=1.6.3

# define the mirror from which to fetch the APR and APR-util source code
ARG APR_MIRROR="https://dlcdn.apache.org"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 2"


FROM alpine:3.13 as intermediate
# ToDo: Upgrade possible if https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.14.0#faccessat2 addressed

# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG OPENSSL_PATH
ARG HTTPD_PATH
ARG SIG_ALG
ARG HTTPD_VERSION
ARG APR_VERSION
ARG APRU_VERSION
ARG APR_MIRROR
ARG MAKE_DEFINES
ARG DEFAULT_GROUPS

# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            git wget pcre-dev \
            expat-dev

# get sources
WORKDIR /opt
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch master https://github.com/openssl/openssl ossl-src && \
    git clone --depth 1 --branch main https://github.com/open-quantum-safe/oqs-provider && \
    wget ${APR_MIRROR}/apr/apr-${APR_VERSION}.tar.gz && tar xzvf apr-${APR_VERSION}.tar.gz && \
    wget ${APR_MIRROR}/apr/apr-util-${APRU_VERSION}.tar.gz && tar xzvf apr-util-${APRU_VERSION}.tar.gz && \
    wget --trust-server-names "https://archive.apache.org/dist/httpd/httpd-${HTTPD_VERSION}.tar.gz" && tar -zxvf httpd-${HTTPD_VERSION}.tar.gz;

# build OpenSSL3 (latest); make libs detectable to old (APRU) tooling not knowing about lib64
WORKDIR /opt/ossl-src
RUN ./config no-shared --prefix=${OPENSSL_PATH} && \
    make ${MAKE_DEFINES} && make install_sw install_ssldirs && \
    ln -s ${OPENSSL_PATH}/lib64 ${OPENSSL_PATH}/lib;

# build liboqs (shared lib only for oqsprovider)
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${OPENSSL_PATH} && ninja && ninja install

# create openssl.cnf activating oqsprovider & setting default groups
RUN sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${OPENSSL_PATH}/ssl/openssl.cnf && sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${OPENSSL_PATH}/ssl/openssl.cnf && sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${OPENSSL_PATH}/ssl/openssl.cnf && sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${OPENSSL_PATH}/ssl/openssl.cnf


# build oqs-provider
WORKDIR /opt/oqs-provider
RUN rm -rf build && cmake -DCMAKE_BUILD_TYPE=Debug -DOPENSSL_ROOT_DIR=${OPENSSL_PATH} -DCMAKE_PREFIX_PATH=${OPENSSL_PATH} -S . -B build && cmake --build build && export MODULESDIR=$(find ${OPENSSL_PATH} -name ossl-modules) && cp build/lib/oqsprovider.so $MODULESDIR/oqsprovider.so

# build httpd
WORKDIR /opt
RUN sed -i "s/\$RM \"\$cfgfile\"/\$RM -f \"\$cfgfile\"/g" apr-${APR_VERSION}/configure && \
    cd apr-${APR_VERSION} && ./configure && make ${MAKE_DEFINES} && make install && cd .. && \
    cd apr-util-${APRU_VERSION} && ./configure x86_64-pc-linux-gnu --with-crypto --with-openssl=${OPENSSL_PATH} --with-apr=/usr/local/apr && make ${MAKE_DEFINES} && make install

WORKDIR /opt/httpd-${HTTPD_VERSION}
RUN ./configure --prefix=${HTTPD_PATH} \
                    --enable-debugger-mode \
                    --enable-ssl --with-ssl=${OPENSSL_PATH} \
                    --enable-ssl-staticlib-deps \
                    --enable-mods-static=ssl && \
    make ${MAKE_DEFINES} && make install;

# prepare to run httpd
ARG OPENSSL_CNF=${OPENSSL_PATH}/ssl/openssl.cnf

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

# Some size optimization:
RUN rm -rf ${HTTPD_PATH}/bin/ab

# second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:3.13

LABEL version="2"

# Take in global args
ARG HTTPD_PATH
ARG OPENSSL_PATH
#
RUN apk add pcre-dev expat-dev
#
# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${HTTPD_PATH} ${HTTPD_PATH}
# copy over manually build libapr{util}
COPY --from=intermediate /usr/local/apr/lib  /usr/local/apr/lib

# Need to copy over OpenSSL3 libs and conf for oqsprovider use
COPY --from=intermediate ${OPENSSL_PATH}/ssl ${OPENSSL_PATH}/ssl
COPY --from=intermediate ${OPENSSL_PATH}/lib64 ${OPENSSL_PATH}/lib64

COPY httpd-conf/httpd-ssl.conf ${HTTPD_PATH}/httpd-conf/httpd-ssl.conf
COPY httpd-conf/httpd.conf ${HTTPD_PATH}/httpd-conf/httpd.conf
WORKDIR ${HTTPD_PATH}

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${HTTPD_PATH}/logs/access_log && \
    ln -sf /dev/stderr ${HTTPD_PATH}/logs/error_log;
#
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs ${HTTPD_PATH}
USER oqs

# Ensure httpd just runs
ENV PATH ${HTTPD_PATH}/bin:$PATH

EXPOSE 4433
#
STOPSIGNAL SIGTERM

CMD ["httpd", "-f", "httpd-conf/httpd.conf", "-D", "FOREGROUND"]

