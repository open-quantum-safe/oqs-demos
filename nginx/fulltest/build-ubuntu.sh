#!/bin/bash

# defines the install path
export NGINX_PATH=/opt/nginx

# define the nginx version to include
export NGINX_VERSION=1.16.1

# define the OQS releases to use; unset to deploy main branch
export LIBOQS_RELEASE=0.4.0

# defines the OQS-OpenSSL version to use; be sure to match with liboqs version
export OPENSSL_RELEASE=OQS-OpenSSL_1_1_1-stable-snapshot-2020-08

# Temporary openssl build path; keep in synch with genconfig.py
export OPENSSL_PATH=/tmp/opt/openssl

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
export MAKE_DEFINES="-j 4"

# prerequisites:
sudo apt install -y libtool automake autoconf cmake make openssl git wget libssl-dev libpcre3-dev

# get OQS sources
rm -rf /tmp/opt && mkdir /tmp/opt && cd /tmp/opt
if [ -z "$LIBOQS_RELEASE" ]; then
git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl 
else
echo "Deploying stable liboqs release ${LIBOQS_RELEASE}"
wget https://github.com/open-quantum-safe/liboqs/archive/${LIBOQS_RELEASE}.tar.gz && tar xzvf ${LIBOQS_RELEASE}.tar.gz && mv liboqs-${LIBOQS_RELEASE} liboqs && \
wget https://github.com/open-quantum-safe/openssl/archive/${OPENSSL_RELEASE}.tar.gz && tar xzvf ${OPENSSL_RELEASE}.tar.gz && mv openssl-${OPENSSL_RELEASE} openssl 
fi
wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs (static only)
cd /tmp/opt/liboqs
mkdir build-static && cd build-static && cmake ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=${OPENSSL_PATH}/oqs .. && make ${MAKE_DEFINES} && make install

# build nginx (which builds OQS-OpenSSL)
cd /tmp/opt/nginx-${NGINX_VERSION}
./configure --prefix=${NGINX_PATH} \
                --with-debug \
                --with-http_ssl_module --with-openssl=${OPENSSL_PATH} \
                --with-stream_ssl_module \
                --without-http_gzip_module \
                --with-cc-opt=-I${OPENSSL_PATH}/oqs/include \
                --with-ld-opt="-L${OPENSSL_PATH}/oqs/lib" && \
    sed -i 's/libcrypto.a/libcrypto.a -loqs/g' objs/Makefile && \
    make ${MAKE_DEFINES} && make modules ;

if [ $# -eq 1 ] && [ $1 = "install" ];  then
   make install
fi

