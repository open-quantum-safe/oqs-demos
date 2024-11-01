# Multi-stage build: First the full builder image:

ARG INSTALLDIR_OPENSSL=/opt/openssl32
ARG INSTALLDIR_LIBOQS=/opt/liboqs

# liboqs build type variant; maximum portability of image:
ARG LIBOQS_BUILD_DEFINES="-DOQS_DIST_BUILD=ON"

# Define the degree of parallelism when building the image; leave the number away only if you know what you are doing
ARG MAKE_DEFINES="-j 8"

ARG SIG_ALG="dilithium3"

FROM alpine:3.20.3 AS buildopenssl
# Take in all global args
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
ARG SIG_ALG

LABEL version="1"
ENV DEBIAN_FRONTEND noninteractive


# Get all software packages required for builing openssl
RUN apk add --no-cache build-base linux-headers \
            libtool automake autoconf \
            make \
            git wget

# get current openssl sources
WORKDIR /optbuild
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/oqs-provider.git

# build OpenSSL3
WORKDIR /optbuild/openssl
RUN LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR_OPENSSL}/lib64" ./config shared --prefix=${INSTALLDIR_OPENSSL} && \
    make ${MAKE_DEFINES} && make install && if [ -d ${INSTALLDIR_OPENSSL}/lib64 ]; then ln -s ${INSTALLDIR_OPENSSL}/lib64 ${INSTALLDIR_OPENSSL}/lib; fi && if [ -d ${INSTALLDIR_OPENSSL}/lib ]; then ln -s ${INSTALLDIR_OPENSSL}/lib ${INSTALLDIR_OPENSSL}/lib64; fi 

FROM alpine:3.20.3 AS buildliboqs
# Take in all global args
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
ARG SIG_ALG

LABEL version="1"
ENV DEBIAN_FRONTEND noninteractive

# Get all software packages required for builing liboqs:
RUN apk add --no-cache build-base linux-headers \
            libtool automake autoconf cmake ninja \
            make \
            git wget

# Get OpenSSL image (from cache)
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

WORKDIR /optbuild
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/liboqs

WORKDIR /optbuild/liboqs/build
RUN cmake -G"Ninja" .. -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} ${LIBOQS_BUILD_DEFINES} -DCMAKE_INSTALL_PREFIX=${INSTALLDIR_LIBOQS} && ninja install

FROM alpine:3.20.3 AS buildoqsprovider
# Take in all global args
ARG INSTALLDIR_OPENSSL
ARG INSTALLDIR_LIBOQS
ARG LIBOQS_BUILD_DEFINES
ARG MAKE_DEFINES
ARG SIG_ALG

LABEL version="1"
ENV DEBIAN_FRONTEND noninteractive

# Get all software packages required for builing oqsprovider
RUN apk add --no-cache build-base linux-headers \
            libtool cmake ninja \
            git wget

WORKDIR /optbuild
RUN git clone --depth 1 --branch main https://github.com/open-quantum-safe/oqs-provider.git

# Get openssl32 and liboqs
COPY --from=buildopenssl ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}
COPY --from=buildliboqs ${INSTALLDIR_LIBOQS} ${INSTALLDIR_LIBOQS}

# build & install provider (and activate by default)
WORKDIR /optbuild/oqs-provider
RUN liboqs_DIR=${INSTALLDIR_LIBOQS} cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR_OPENSSL} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR_OPENSSL} -S . -B _build && cmake --build _build  && cmake --install _build && cp _build/lib/oqsprovider.so ${INSTALLDIR_OPENSSL}/lib64/ossl-modules && sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = \$ENV\:\:DEFAULT_GROUPS\n/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf && sed -i "s/HOME\t\t\t= ./HOME           = .\nDEFAULT_GROUPS = kyber768/g" ${INSTALLDIR_OPENSSL}/ssl/openssl.cnf

WORKDIR ${INSTALLDIR_OPENSSL}/bin
# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"

# generate CA key and cert
RUN set -x; \
    openssl req -x509 -new -newkey ${SIG_ALG} -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365

## second stage: Only create minimal image without build tooling and intermediate build results generated above:
FROM alpine:3.20.3 AS dev
# Take in all global args
ARG INSTALLDIR_OPENSSL
ARG SIG_ALG

# Only retain the ${INSTALLDIR_OPENSSL} contents in the final image
COPY --from=buildoqsprovider ${INSTALLDIR_OPENSSL} ${INSTALLDIR_OPENSSL}

# set path to use 'new' openssl. Dyn libs have been properly linked in to match
ENV PATH="${INSTALLDIR_OPENSSL}/bin:${PATH}"

# generate certificates for openssl s_server, which is what we will test curl against
WORKDIR ${INSTALLDIR_OPENSSL}/bin

# generate server CSR using pre-set CA.key and cert
# and generate server cert
RUN set -x && mkdir -p /opt/test; \
    openssl version && openssl list -providers && openssl req -new -newkey ${SIG_ALG} -keyout /opt/test/server.key -out /opt/test/server.csr -nodes -subj "/CN=localhost" && \
    openssl x509 -req -in /opt/test/server.csr -out /opt/test/server.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365;

COPY serverstart.sh ${INSTALLDIR_OPENSSL}/bin

WORKDIR ${INSTALLDIR_OPENSSL}

FROM dev
ARG INSTALLDIR_OPENSSL

WORKDIR /

# Enable a normal user to create new server keys off set CA
RUN addgroup -g 1000 -S oqs && adduser --uid 1000 -S oqs -G oqs && chown -R oqs.oqs /opt/test && chmod go+r ${INSTALLDIR_OPENSSL}/bin/CA.key 

#USER oqs
CMD ["serverstart.sh"]
STOPSIGNAL SIGTERM
