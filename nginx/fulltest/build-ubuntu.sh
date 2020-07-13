export NGINX_PATH=/opt/nginx
export OPENSSL_PATH=/tmp/opt/openssl

# define the nginx version to include
export NGINX_VERSION=1.16.1

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
export MAKE_DEFINES="-j 4"


# prerequisites:
sudo apt install libtool automake autoconf cmake make openssl git wget libssl-dev libpcre3-dev

# get OQS sources
rm -rf /tmp/opt && mkdir /tmp/opt && cd /tmp/opt
git clone --depth 1 --branch master https://github.com/open-quantum-safe/liboqs && \
git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl && \
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
    make ${MAKE_DEFINES} && make modules && make install;

