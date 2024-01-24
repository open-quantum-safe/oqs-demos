# Multi-stage build: First the full builder image:
FROM alpine as intermediate

ENV DEBIAN_FRONTEND=noninteractive

ARG LIBOQS_TAG=main
ARG OQSPROVIDER_TAG=main
ARG INSTALLDIR=/opt/oqssa

# Update image and apt software 
RUN apk update && apk upgrade

# All build prerequisites for the various software packages:
RUN apk add bash git g++ make cmake ninja autoconf automake libtool \
    libev-dev libevent-dev openssl-dev openssl zlib c-ares-dev pkgconfig \
    linux-headers zlib-dev jansson-dev

WORKDIR /opt

# get all sources
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch master https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch master  https://github.com/nghttp2/nghttp2.git

# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -GNinja -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} .. && ninja && ninja install

# build openssl 3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared --prefix=${INSTALLDIR} && \
    make ${MAKE_DEFINES} && make install_sw install_ssldirs

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules && sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:KEM_ALG\n/g" /opt/oqssa/ssl/openssl.cnf && sed -i "s/\# Use this in order to automatically load providers/\# Set default KEM alg if not set via environment variable\nKEM_ALG = kyber512\n\n# Use this in order to automatically load providers/g" /opt/oqssa/ssl/openssl.cnf


# build nghttp2
WORKDIR /opt/nghttp2
RUN LD_LIBRARY_PATH=${INSTALLDIR}/lib64 autoreconf -i && automake && autoconf && ./configure \
    PKG_CONFIG_PATH="/opt/oqssa/lib64/pkgconfig"  && make -j$(nproc) install

# Copy all required shared object dependencies to a single directory
RUN mkdir /opt/lib && cd /opt/lib && \
        cp /usr/local/lib/libnghttp2.so.* . && \
        cp /usr/lib/libev.so.* . && \
        cp /opt/oqssa/lib64/libssl.so.* . && \
        cp /opt/oqssa/lib64/libcrypto.so.* . && \
        cp /usr/lib/libstdc++.so.* . && \
        cp /usr/lib/libgcc_s.so.* .

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine as dev
ENV DEBIAN_FRONTEND=noninteractive

# copy executable
COPY --from=intermediate /usr/local/bin/h2load /usr/local/bin
COPY check_algorithms.sh /usr/local/bin

# copy shared object dependencies and configuration file
COPY --from=intermediate /opt/lib /usr/local/lib
COPY --from=intermediate /opt/oqssa/lib64/ossl-modules/oqsprovider.so /opt/oqssa/lib64/ossl-modules/oqsprovider.so
COPY --from=intermediate /opt/oqssa/ssl/openssl.cnf /opt/oqssa/ssl/openssl.cnf
