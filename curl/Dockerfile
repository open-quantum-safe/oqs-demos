FROM debian:buster-slim

ENV CURL_VERSION 7.66.0

RUN apt-get update -qq \
    && apt-get install -y build-essential \
                          git \
                          # OQS
                          autoconf \
                          automake \
                          libtool \
                          libssl-dev \
                          # misc
                          wget;

# get sources
WORKDIR /opt
RUN git clone --single-branch --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --single-branch --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl ossl-src && \
    wget https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz && tar -zxvf curl-${CURL_VERSION}.tar.gz;

# build liboqs
WORKDIR /opt/liboqs
RUN autoreconf -i && \
    ./configure --prefix=/opt/ossl-src/oqs --enable-shared=no && \
    make -j && \
    make install;

# build OQS-OpenSSL
WORKDIR /opt/ossl-src
# curl looks for shared libraries
# at ./configure time
RUN ./config shared --prefix=/opt/openssl && \
    make && make install_sw;

# build curl
WORKDIR /opt/curl-${CURL_VERSION}
RUN env CPPFLAGS="-I/opt/ossl-src/oqs/include" \
        ./configure --prefix=/opt/curl \
                    --enable-debug \
                    --with-ssl=/opt/openssl && \
    sed -i 's/EVP_MD_CTX_create/EVP_MD_CTX_new/g; s/EVP_MD_CTX_destroy/EVP_MD_CTX_free/g' lib/vtls/openssl.c && \
    make && make install;

# ensure dynamic linker looks in the
# right place for libssl and libcrypto
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/opt/openssl/lib"

# generate certificates for
# openssl s_server, which is
# what we will test curl against
ARG OPENSSL=/opt/openssl/bin/openssl
ARG OPENSSL_CNF=/opt/ossl-src/apps/openssl.cnf

ARG SIG_ALG="dilithium2"

WORKDIR /opt/openssl/bin
RUN set -x && \
    # generate CA key and cert
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    # generate server CSR
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout /server.key -out server.csr -nodes -subj "/CN=oqstest CA" -config ${OPENSSL_CNF} && \
    # generate server cert
    ${OPENSSL} x509 -req -in server.csr -out /server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

WORKDIR /
