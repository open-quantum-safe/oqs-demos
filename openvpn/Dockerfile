# Multi-stage build: First the full builder image:

# define the openssl tag to be used
ARG OPENSSL_TAG=openssl-3.3.2

# define the liboqs tag to be used
ARG LIBOQS_TAG=0.11.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.7.0

ARG OPENVPN_TAG=v2.6.12

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# Location where all default OpenVPN config files wind up:
ARG OPENVPNDIR=/home/openvpn

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 4"

# Default KEM algorithms to be utilized
ARG KEM_ALGLIST="mlkem768:p384_mlkem768"

FROM debian:bullseye AS intermediate
# Take in all global args
ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG OPENVPN_TAG
ARG INSTALLDIR
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
ARG KEM_ALGLIST
ARG OPENVPNDIR

LABEL version="3"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt -y upgrade

# Get all software packages required for builing all components:
RUN apt install -y  \
            libtool automake autoconf cmake ninja-build \
            make \
            openssl libssl-dev pkg-config libcap-ng-dev \
            git docker wget vim net-tools \
            liblzo2-dev libpam0g-dev python3-docutils \
            libnl-3-dev libnl-genl-3-dev

# get all sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${OPENVPN_TAG} https://github.com/OpenVPN/openvpn.git

# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} && ninja install

# build OpenSSL3
WORKDIR /opt/openssl
RUN openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/$openssl_libdir" ./config shared --prefix=${INSTALLDIR} && \
    make ${MAKE_DEFINES} && \
    make install_sw install_ssldirs;

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/$openssl_libdir/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf


# build openvpn based on OpenSSL3

ENV OPENSSL3_DIR=${INSTALLDIR}

WORKDIR /opt/openvpn

RUN openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    libtoolize --force && \
    aclocal && \
    autoheader && \
    automake --force-missing --add-missing && \
    autoconf && \
    CFLAGS="-I$OPENSSL3_DIR/include -Wl,-rpath=$OPENSSL3_DIR/$openssl_libdir -L$OPENSSL3_DIR/$openssl_libdir" ./configure --prefix=${INSTALLDIR} --disable-lz4 && \
    make ${MAKE_DEFINES} && \
    make check && \
    make install

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM debian:bullseye-slim
# Take in all global args
ARG INSTALLDIR
ARG OPENVPNDIR

# install basics to run executable and enable network control
RUN apt update && apt upgrade -y && \
    apt install -y liblzo2-2 \
    libnl-3-200 \
    libnl-genl-3-200 \
    procps \
    net-tools \
    iputils-ping && \
    mkdir -p ${OPENVPNDIR}

# Only retain the ${INSTALLDIR} contents in the final image
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# set path to use openssl built. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${INSTALLDIR}/sbin:${PATH}"

COPY serverstart.sh ${INSTALLDIR}/bin
COPY clientstart.sh ${INSTALLDIR}/bin
COPY openvpn-openssl.cnf ${OPENVPNDIR}
COPY server.config ${OPENVPNDIR}
COPY client.config ${OPENVPNDIR}
COPY createcerts_and_config.sh ${INSTALLDIR}/bin

WORKDIR ${OPENVPNDIR}

# Activate to limit access to normal user rights
#RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs
#USER oqs

CMD ["serverstart.sh"]
STOPSIGNAL SIGTERM
