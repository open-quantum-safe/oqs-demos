# Multi-stage build: First the full builder image:
FROM alpine as intermediate

ENV DEBIAN_FRONTEND=noninteractive

# Update image and apt software 
RUN apk update && apk upgrade

# All build prerequisites for the various software packages:
RUN apk add bash git g++ make cmake ninja autoconf automake libtool \
    libev-dev libevent-dev openssl-dev openssl zlib c-ares-dev pkgconfig \
    linux-headers zlib-dev jansson-dev

WORKDIR /opt

# get all sources
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch main  https://github.com/ngtcp2/nghttp3 && \
    git clone --depth 1 --branch main https://github.com/ngtcp2/ngtcp2 && \
    git clone --depth 1 --branch master  https://github.com/nghttp2/nghttp2.git


COPY merge-oqs-openssl-quic.sh /opt
RUN ./merge-oqs-openssl-quic.sh mergeonly

# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -GNinja -DCMAKE_INSTALL_PREFIX=/opt/oqs-openssl-quic/oqs .. && ninja && ninja install


# build oqs-openssl-quic
WORKDIR /opt/oqs-openssl-quic
RUN ./config enable-tls1_3 --prefix=$PWD/build && make -j$(nproc) && make install_sw


# build nghttp3
WORKDIR /opt/nghttp3
RUN autoreconf -i && ./configure --prefix=$PWD/build --enable-lib-only && make -j$(nproc) check && make install


# build ngtcp2
WORKDIR /opt/ngtcp2
RUN autoreconf -i && ./configure PKG_CONFIG_PATH=$PWD/../oqs-openssl-quic/build/lib/pkgconfig:$PWD/../nghttp3/build/lib/pkgconfig LDFLAGS="-Wl,-rpath,$PWD/../oqs-openssl-quic/build/lib"  CXX=g++ CXXFLAGS="-std=c++20"  && make -j$(nproc) && make install 


# build nghttp2
WORKDIR /opt/nghttp2
RUN autoreconf -i && ./configure --enable-http3 \
    PKG_CONFIG_PATH="$PWD/../oqs-openssl-quic/build/lib/pkgconfig:$PWD/../nghttp3/build/lib/pkgconfig:$PWD/../ngtcp2/crypto/openssl/" \
    LDFLAGS="$LDFLAGS -Wl,-rpath,$PWD/../oqs-openssl-quic/build/lib" && make -j$(nproc) install

# Copy all required shared object dependencies to a single directory
RUN mkdir /opt/lib && cd /opt/lib && \
        cp /usr/local/lib/libnghttp2.so.14 . && \
        cp /opt/ngtcp2/lib/.libs/libngtcp2.so.11 . && \
        cp /usr/lib/libev.so.4 . && \
        cp /opt/nghttp3/build/lib/libnghttp3.so.5 . && \
        cp /opt/ngtcp2/crypto/openssl/.libs/libngtcp2_crypto_openssl.so.4 . && \
        cp /opt/oqs-openssl-quic/build/lib/libssl.so.81.1.1 . && \
        cp /opt/oqs-openssl-quic/build/lib/libcrypto.so.81.1.1 . && \
        cp /usr/lib/libstdc++.so.6 . && \
        cp /usr/lib/libgcc_s.so.1 . 

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine as dev
ENV DEBIAN_FRONTEND=noninteractive

# copy executable
COPY --from=intermediate /usr/local/bin/h2load /usr/local/bin

# copy shared object dependencies 
COPY --from=intermediate /opt/lib /usr/local/lib

# COPY --from=intermediate /usr/local/lib/libnghttp2.so.14 /usr/local/lib
# COPY --from=intermediate /usr/lib/libev.so.4 /usr/local/lib
# COPY --from=intermediate /opt/nghttp3/build/lib/libnghttp3.so.5 /usr/local/lib
# COPY --from=intermediate /usr/local/lib/libngtcp2_crypto_openssl.so.4 /usr/local/lib
# COPY --from=intermediate /usr/local/lib/libngtcp2.so.11 /usr/local/lib
# COPY --from=intermediate /opt/oqs-openssl-quic/build/lib/libssl.so.81.1.1 /usr/local/lib
# COPY --from=intermediate /opt/oqs-openssl-quic/build/lib/libcrypto.so.81.1.1 /usr/local/lib
# COPY --from=intermediate /usr/lib/libstdc++.so.6 /usr/local/lib
# COPY --from=intermediate /usr/lib/libgcc_s.so.1 /usr/local/lib