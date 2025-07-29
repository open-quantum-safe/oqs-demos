# Multi-stage build: First the full builder image:

# First: global build arguments:

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_TAG=0.14.0

ARG OPENSSL_TAG=openssl-3.4.2

ARG OQSPROVIDER_TAG=0.9.0

ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# base install path
ARG BASEDIR="/opt"

# installation paths
ARG INSTALLDIR=${BASEDIR}/nginx

ARG CONFIGDIR="/"

# defines the list of default groups to be activated in nginx-openssl config:
ARG DEFAULT_GROUPS=x25519:x448:prime256v1:secp384r1:secp521r1:kyber512:x25519_kyber768:p256_kyber512:kyber768:p384_kyber768:kyber1024:p521_kyber1024:mlkem512:mlkem768:mlkem1024:X25519MLKEM768:SecP256r1MLKEM768

# define the nginx version to include
ARG NGINX_VERSION=1.27.4

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j"

# Root CA directory
ARG CAROOTDIR="/rootca"

FROM redhat/ubi9:9.5-1742918310 AS intermediate
# Take in global args
ARG BASEDIR
ARG CONFIGDIR
ARG CAROOTDIR
ARG LIBOQS_TAG
ARG OPENSSL_TAG
ARG OQSPROVIDER_TAG
ARG LIBOQS_BUILD_DEFINES
ARG INSTALLDIR
ARG NGINX_VERSION
ARG MAKE_DEFINES
ARG DEFAULT_GROUPS
ARG OSSLDIR=${BASEDIR}/openssl/.openssl

ENV DEBIAN_FRONTEND noninteractive
# Get all software packages required for builing all components (probably not all are really needed):
RUN dnf update -y && \
    dnf install -y sed perl java-openjdk git python3-pip && \
    dnf install -y pcre pcre-devel libtool automake autoconf && \
    dnf install -y openssl openssl-devel gcc gcc-c++ make cmake && \
    dnf install -y ninja-build unzip libxslt graphviz valgrind wget patch && \
    pip3 install pyyaml psutil pytest pytest-xdist && \
    wget https://downloads.lightbend.com/scala/2.13.15/scala-2.13.15.rpm && \
    dnf localinstall -y scala-2.13.15.rpm

#RUN dnf update && dnf install -y sed perl java-openjdk git python3-pip pcre pcre-devel libtool automake autoconf openssl openssl-devel gcc gcc-c++ make cmake ninja-build unzip libxslt graphviz valgrind wget patch && pip3 install pyyaml psutil pytest pytest-xdist && wget https://downloads.lightbend.com/scala/2.13.15/scala-2.13.15.rpm && dnf localinstall -y scala-2.13.15.rpm

# get OQS sources
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    wget nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz;

# build liboqs (static only)
WORKDIR /opt/liboqs
RUN mkdir build && cd build && cmake -G"Ninja" ${LIBOQS_BUILD_DEFINES} -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} .. && ninja && ninja install

COPY ngx_event_openssl.patch /opt/nginx-${NGINX_VERSION}
# build nginx (also building openssl)
WORKDIR /opt/nginx-${NGINX_VERSION}
RUN patch -p1 < ngx_event_openssl.patch
RUN ./configure --prefix=${INSTALLDIR} \
                --with-debug \
                --with-http_ssl_module --with-openssl=/opt/openssl \
                --without-http_gzip_module && \
    make ${MAKE_DEFINES} && make install;

# create openssl.cnf activating oqsprovider & setting default groups
RUN mkdir -p ${OSSLDIR}/ssl && cp /opt/openssl/apps/openssl.cnf ${OSSLDIR}/ssl/ && sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${OSSLDIR}/ssl/openssl.cnf && sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${OSSLDIR}/ssl/openssl.cnf && sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${OSSLDIR}/ssl/openssl.cnf && sed -i "s/HOME\t\t\t= ./HOME\t\t= .\nDEFAULT_GROUPS\t= ${DEFAULT_GROUPS}/g" ${OSSLDIR}/ssl/openssl.cnf

# build oqsprovider
WORKDIR /opt/oqs-provider

RUN ln -s /opt/nginx/include/oqs ${OSSLDIR}/include && rm -rf build && cmake -DCMAKE_C_STANDARD_LIBRARIES="-ldl -pthread" -DOPENSSL_ROOT_DIR=${OSSLDIR} -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B build && cmake --build build && mkdir -p ${OSSLDIR}/lib64/ossl-modules && cp build/lib/oqsprovider.so ${OSSLDIR}/lib64/ossl-modules && rm -rf ${INSTALLDIR}/lib64

WORKDIR ${INSTALLDIR}

# Test/Utilize oqsprovider:
    # generate CA key and cert
    # generate server CSR
    # generate server cert

ENV PATH ${INSTALLDIR}/sbin:${OSSLDIR}/bin:$PATH
# begin optimizing sizes:
RUN strip ${OSSLDIR}/lib/*.a ${OSSLDIR}/lib64/ossl-modules/oqsprovider.so ${INSTALLDIR}/sbin/* ${INSTALLDIR}/sbin/*

WORKDIR ${CONFIGDIR}

#copies genconfig.py script
COPY genconfig.py ${CONFIGDIR}
COPY common.py ${CONFIGDIR}
COPY ext-csr.conf ${CONFIGDIR}
COPY index-template ${CONFIGDIR}
#COPY chromium-template ${CONFIGDIR}
COPY success.htm ${CONFIGDIR}
COPY OsslAlgParser.scala ${CONFIGDIR}
# copy existing rootca directory if it exists
COPY rootc[a] ${CAROOTDIR} 
RUN cp /opt/oqs-provider/oqs-template/generate.yml ${CONFIGDIR}

RUN for i in 128 192 256; do echo "seclevel:$i"; OPENSSL_MODULES=${OSSLDIR}/lib64/ossl-modules /opt/openssl/apps/openssl list -provider oqsprovider -propquery oqsprovider.security_bits=$i -kem-algorithms; done | scala -nobootcp -nc OsslAlgParser.scala key_exchanges >> oqsprovider_alglist.py
RUN for i in 128 192 256; do echo "seclevel:$i"; OPENSSL_MODULES=${OSSLDIR}/lib64/ossl-modules /opt/openssl/apps/openssl list -provider oqsprovider -propquery oqsprovider.security_bits=$i -signature-algorithms; done | scala -nobootcp -nc OsslAlgParser.scala signatures >> oqsprovider_alglist.py

RUN python3 genconfig.py

RUN sed -i "s/LIBOQS_RELEASE/${LIBOQS_TAG}/g" index-base.html
RUN sed -i "s/OQSPROVIDER_RELEASE/${OQSPROVIDER_TAG}/g" index-base.html
#RUN sed -i "s/LIBOQS_RELEASE/${LIBOQS_TAG}/g" chromium-base.html
#RUN sed -i "s/OQSPROVIDER_RELEASE/${OQSPROVIDER_TAG}/g" chromium-base.html

RUN rm -rf ${INSTALLDIR}/pki
RUN rm -rf ${INSTALLDIR}/logs/*
RUN cp -R pki ${INSTALLDIR}
RUN cp interop.conf ${INSTALLDIR}
RUN mkdir -p ${INSTALLDIR}/html
RUN cp *.html ${INSTALLDIR}/html
RUN cp rootca/CA.crt ${INSTALLDIR}/html
RUN cp success.htm ${INSTALLDIR}/html/success.html
RUN cp assignments.json ${INSTALLDIR}/html/

# further optimize sizes:
RUN rm ${OSSLDIR}/bin/*

# second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM redhat/ubi9:9.5-1742918310
# Take in global args
ARG LIBOQS_BUILD_DEFINES
ARG LIBOQS_VERSION
ARG INSTALLDIR
ARG CAROOTDIR
ARG BASEDIR
ARG OSSLDIR=${BASEDIR}/openssl/.openssl

LABEL version="2"

ENV DEBIAN_FRONTEND noninteractive
#RUN apk add pcre-dev
RUN dnf update -y && dnf install -y pcre pcre-devel

# Only retain the ${*_PATH} contents in the final image
COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}
COPY --from=intermediate ${OSSLDIR} ${OSSLDIR}
COPY --from=intermediate ${CAROOTDIR} ${CAROOTDIR}

# Package for deployment
RUN tar czvf oqs-nginx-0.14.0.tgz ${BASEDIR}

# Package for root CA cert and key
RUN tar czvf oqs-testserver-rootca-0.14.0.tgz ${CAROOTDIR}
