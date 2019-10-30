FROM debian:buster-slim

ENV HTTPD_VERSION 2.4.41

RUN apt-get update -qq \
    && apt-get install -y build-essential \
                          git \
                          # OQS
                          autoconf \
                          automake \
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
RUN git clone --single-branch --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --single-branch --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl ossl-src && \
    wget --trust-server-names "https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename=httpd/httpd-${HTTPD_VERSION}.tar.gz" && tar -zxvf httpd-${HTTPD_VERSION}.tar.gz;

# build liboqs
WORKDIR /opt/liboqs
RUN autoreconf -i && \
    ./configure --prefix=/opt/ossl-src/oqs --enable-shared=no && \
    make -j && \
    make install;

# build OQS-OpenSSL
WORKDIR /opt/ossl-src
RUN ./config no-shared --prefix=/opt/openssl && \
    make && make install_sw;

# build httpd
WORKDIR /opt/httpd-${HTTPD_VERSION}
RUN sed -i 's,-lcrypto,-lcrypto /opt/ossl-src/oqs/lib/liboqs.a -ldl,g' configure && \
    env CPPFLAGS="-I/opt/ossl-src/oqs/include" \
        ./configure --prefix=/opt/httpd \
                    --enable-debugger-mode \
                    --enable-ssl --with-ssl=/opt/openssl \
                    --enable-ssl-staticlib-deps \
                    --enable-mods-static=ssl && \
    # Append liboqs to the PROGRAM_LDADD variable definition in the generated Makefile
    sed -i 's,(LIBS),(LIBS) /opt/ossl-src/oqs/lib/liboqs.a,g' Makefile && \
    make && make install;

# prepare to run httpd
ARG OPENSSL=/opt/openssl/bin/openssl
ARG OPENSSL_CNF=/opt/ossl-src/apps/openssl.cnf

ARG SIG_ALG=rsa:3072

WORKDIR /opt/httpd
COPY httpd.conf conf/httpd.conf
COPY httpd-ssl.conf conf/extra/httpd-ssl.conf
RUN set -x && \
    # generate CA key and cert
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    # generate server CSR
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout conf/server.key -out server.csr -nodes -subj "/CN=oqstest CA" -config ${OPENSSL_CNF} && \
    # generate server cert
    ${OPENSSL} x509 -req -in server.csr -out conf/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/httpd/logs/access_log && \
    ln -sf /dev/stderr /opt/httpd/logs/error_log;

EXPOSE 4433

STOPSIGNAL SIGTERM

CMD ["/opt/httpd/bin/httpd", "-DFOREGROUND"]
