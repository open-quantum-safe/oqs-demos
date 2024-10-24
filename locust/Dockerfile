# define the liboqs tag to be used
ARG LIBOQS_TAG=0.11.0

# define the oqsprovider tag to be used
ARG OQSPROVIDER_TAG=0.7.0

# define the openssl version to be baked in
ARG OPENSSL_BRANCH=openssl-3.3.2

# Default location where all binaries wind up:
ARG INSTALLDIR=/opt/oqssa

# Default Python version to be used
ARG PYTHON_VERSION=3.12.6

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Default root CA signature algorithm; can be set to any listed at https://github.com/open-quantum-safe/oqs-provider#algorithms
ARG SIG_ALG="dilithium3"

# Default KEM algorithms; can be set to any listed at https://github.com/open-quantum-safe/oqs-provider#algorithms
ARG DEFAULT_GROUPS="x25519:x448:kyber512:p256_kyber512:kyber768:p384_kyber768:kyber1024:p521_kyber1024"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 16"

# Define the Alpine version to be used
ARG ALPINE_VERSION=3.20.3

FROM alpine:${ALPINE_VERSION}
# Take in all global args
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG LIBOQS_BUILD_DEFINES
ARG SIG_ALG
ARG DEFAULT_GROUPS
ARG MAKE_DEFINES
ARG PYTHON_VERSION
ARG OPENSSL_BRANCH

LABEL version="1"

ENV DEBIAN_FRONTEND noninteractive
ENV LD_LIBRARY_PATH=${INSTALLDIR}/lib

RUN apk update && apk upgrade

# Get all software packages required for builing all components:
RUN apk add build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            git wget vim nano zlib-dev py3-pip tcpdump python3-dev

# get all sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_BRANCH} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git

# build OpenSSL3
WORKDIR /opt/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/lib64" ./config shared enable-zlib no-comp --prefix=${INSTALLDIR} && \
    make ${MAKE_DEFINES} && make install_sw install_ssldirs install_dev && \
    if [ -d ${INSTALLDIR}/lib64 ]; then ln -s ${INSTALLDIR}/lib64 ${INSTALLDIR}/lib; fi && \
    if [ -d ${INSTALLDIR}/lib ]; then ln -s ${INSTALLDIR}/lib ${INSTALLDIR}/lib64; fi


# build liboqs
WORKDIR /opt/liboqs
RUN mkdir build &&  \
    cd build  &&  \
    cmake -G"Ninja" .. ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR}  &&  \
    ninja install

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR}/bin:${PATH}"
ENV LD_LIBRARY_PATH=${INSTALLDIR}/lib

# build & install provider (and activate by default)
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . &&  \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build &&  \
    cmake --build _build  &&  \
    cp _build/lib/oqsprovider.so ${INSTALLDIR}/lib64/ossl-modules &&  \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf &&  \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf &&  \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" /opt/oqssa/ssl/openssl.cnf &&  \
    sed -i "s/\# Use this in order to automatically load providers/\# Set default KEM groups if not set via environment variable\nKDEFAULT_GROUPS = $DEFAULT_GROUPS\n\n# Use this in order to automatically load providers/g" /opt/oqssa/ssl/openssl.cnf &&  \
    sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" /opt/oqssa/ssl/openssl.cnf

# generate certificates for openssl s_server
ENV OPENSSL=${INSTALLDIR}/bin/openssl
ENV OPENSSL_CNF=${INSTALLDIR}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR}/bin
# generate CA key and cert
RUN set -x; \
    ${OPENSSL} req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config ${OPENSSL_CNF}

# Download current test.openquantumsafe.org test CA cert
WORKDIR ${INSTALLDIR}
RUN wget --no-check-certificate https://test.openquantumsafe.org/CA.crt &&  \
    mv CA.crt oqs-testca.pem

# Install Locust
RUN mkdir /home/locust && cd /home/locust
ENV CFLAGS="-I/opt/python-${PYTHON_VERSION}-custom/include/${PYTHON_VERSION}"
ENV LDFLAGS="-L/opt/python-${PYTHON_VERSION}-custom/lib"
COPY requirements.txt /home/locust
RUN pip3 install --break-system-packages --upgrade pip
RUN pip3 install  --break-system-packages -r /home/locust/requirements.txt
ADD / /mnt/locust

