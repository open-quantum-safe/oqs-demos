FROM debian:buster-slim

ENV NGINX_VERSION 1.16.1

RUN apt-get update -qq \
    && apt-get install -y build-essential \
                          git \
                          # OQS
                          autoconf \
                          automake \
                          libtool \
                          libssl-dev \
                          # nginx
                          libpcre3-dev \
                          # misc
                          wget;

# get sources
WORKDIR /opt
RUN git clone --single-branch --branch master https://github.com/open-quantum-safe/liboqs && \
    git clone --single-branch --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl && \
    wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs
WORKDIR /opt/liboqs
RUN autoreconf -i && \
    ./configure --prefix=/opt/openssl/oqs --enable-shared=no && \
    make -j && \
    make install;

# build nginx (which builds OQS-OpenSSL)
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN ./configure --prefix=/opt/nginx \
                --with-debug \
                --with-http_ssl_module --with-openssl=/opt/openssl \
                --without-http_gzip_module \
                --with-cc-opt="-I /opt/openssl/oqs/include" \
                --with-ld-opt="-L /opt/openssl/oqs/lib" && \
    sed -i 's/libcrypto.a/libcrypto.a -loqs/g' objs/Makefile && \
    sed -i 's/EVP_MD_CTX_create/EVP_MD_CTX_new/g; s/EVP_MD_CTX_destroy/EVP_MD_CTX_free/g' src/event/ngx_event_openssl.c && \
    make && make install;

# prepare to run nginx
ARG OPENSSL=/opt/openssl/apps/openssl
ARG OPENSSL_CNF=/opt/openssl/apps/openssl.cnf

ARG SIG_ALG

WORKDIR /opt/nginx
COPY nginx.conf conf/nginx.conf
RUN set -x && \
    # generate CA key and cert
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF} && \
    # generate server CSR
    ${OPENSSL} req -new -newkey ${SIG_ALG} -keyout server.key -out server.csr -nodes -subj "/CN=oqstest CA" -config ${OPENSSL_CNF} && \
    # generate server cert
    ${OPENSSL} x509 -req -in server.csr -out server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/nginx/access.log && \
    ln -sf /dev/stderr /opt/nginx/error.log;

EXPOSE 4433

STOPSIGNAL SIGTERM

CMD ["/opt/nginx/sbin/nginx", "-g", "daemon off;"]
