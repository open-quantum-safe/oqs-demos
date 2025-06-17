
# Define build arguments for version tags, installation paths, and configurations
ARG UBUNTU_VERSION=22.04 # does not work on 24.04 `Failed to create XdpPortal instance: Failed to execute child process "dbus-launch" (No such file or directory)`
ARG INSTALLDIR=/opt/oqssa

# OpenSSL/OQS Versions
ARG OPENSSL_TAG=openssl-3.4.0
ARG LIBOQS_TAG=0.13.0
ARG OQSPROVIDER_TAG=0.9.0

# architecture to build on
ARG ARCH=x86_64

# Specify supported key encapsulation mechanisms (KEM) algorithms
# added x25519 so that it's possible browse normal websites
ARG KEM_ALGLIST="mlkem768:p384_mlkem768:x25519"

# Stage 1: Build - Compile and assemble all necessary components and dependencies
FROM ubuntu:${UBUNTU_VERSION} AS intermediate
LABEL version="2"

ARG OPENSSL_TAG
ARG LIBOQS_TAG
ARG OQSPROVIDER_TAG
ARG INSTALLDIR
ARG KEM_ALGLIST
ARG ARCH

ENV DEBIAN_FRONTEND=noninteractive

# Install openssl/oqs required build tools and system dependencies
RUN echo "Architecture build set to:" $ARCH && \
    apt-get update && apt-get install -y --no-install-recommends \
            libtool automake autoconf cmake ninja-build ca-certificates \
            make pkg-config \
            git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and prepare source files needed for the build process
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OPENSSL_TAG} https://github.com/openssl/openssl.git && \
    git clone --depth 1 --branch ${OQSPROVIDER_TAG} https://github.com/open-quantum-safe/oqs-provider.git

# Build and install OpenSSL
WORKDIR /opt/openssl
RUN openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    LDFLAGS="-Wl,-rpath -Wl,${INSTALLDIR}/$openssl_libdir" ./config shared --prefix=${INSTALLDIR} && \
    make -j"$(nproc)" && make install_sw install_ssldirs;

# Set PATH to include the new OpenSSL binaries
ENV PATH="${INSTALLDIR}/bin:${PATH}"

# Build and install liboqs
WORKDIR /opt/liboqs/build
RUN cmake -G"Ninja" ..  \
    -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DOPENSSL_CRYPTO_LIBRARY=$INSTALLDIR/include -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DOQS_USE_OPENSSL=OFF && ninja install

# Build, install, and configure the oqs-provider for OpenSSL integration
WORKDIR /opt/oqs-provider
RUN ln -s ../openssl . && \
    openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    cmake -DOPENSSL_ROOT_DIR=${INSTALLDIR} -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=${INSTALLDIR} -S . -B _build && \
    cmake --build _build  && cp _build/lib/oqsprovider.so ${INSTALLDIR}/$openssl_libdir/ossl-modules && \
    sed -i "s/default = default_sect/default = default_sect\noqsprovider = oqsprovider_sect/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/\[default_sect\]/\[default_sect\]\nactivate = 1\n\[oqsprovider_sect\]\nactivate = 1\n/g" /opt/oqssa/ssl/openssl.cnf && \
    sed -i "s/providers = provider_sect/providers = provider_sect\nssl_conf = ssl_sect\n\n\[ssl_sect\]\nsystem_default = system_default_sect\n\n\[system_default_sect\]\nGroups = ${KEM_ALGLIST}\n/g" /opt/oqssa/ssl/openssl.cnf


# build glib-networking with openssl and not GnuTLS
RUN apt update && apt install -y \
    build-essential clang meson gnome-pkg-tools libglib2.0-dev libproxy-dev gsettings-desktop-schemas-dev

RUN git clone https://gitlab.gnome.org/GNOME/glib-networking.git && \
    cd glib-networking && \
    git checkout 2.72.2 && \
    mkdir build && \
    cd build && \
    openssl_libdir='lib64' && if [ "$(uname -m)" = "aarch64" ]; then openssl_libdir='lib'; fi && \
    PKG_CONFIG_PATH=${INSTALLDIR}/$openssl_libdir/pkgconfig CPATH=${INSTALLDIR}/include LIBRARY_PATH=${INSTALLDIR}/$openssl_libdir  meson --prefix=${INSTALLDIR} -Dopenssl=enabled -Dgnutls=disabled .. && \
    CPATH=${INSTALLDIR}/include ninja && \
    ninja install

# added for debugging purposes, openquantumsafe certificate and epiphany browser not installed.
ENTRYPOINT ["/bin/bash"]

#
# 2nd build step: Only retain what's necessary
#
FROM ubuntu:${UBUNTU_VERSION}
ARG INSTALLDIR
ARG ARCH
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && apt install -y epiphany-browser ca-certificates wget

COPY --from=intermediate ${INSTALLDIR} ${INSTALLDIR}

# Run everything under a limited user account:
RUN groupadd -g 2000 oqs && useradd -u 2000 --home /home/oqs -m -g oqs oqs

# install the test.openquantumsafe.org certificate into the root certs for ubuntu
RUN rm -fr ${INSTALLDIR}/ssl/certs && \
    ln -s /etc/ssl/certs ${INSTALLDIR}/ssl/certs && \
    wget https://test.openquantumsafe.org/CA.crt -O /usr/local/share/ca-certificates/oqsrootca.crt && \
    update-ca-certificates

# Switch the the oqs user
USER oqs

# required to find the openssl libraries are they are dynamically loaded by GIO
# use both lib and lib64 to cover intel and arm
ENV LD_LIBRARY_PATH=${INSTALLDIR}/lib:${INSTALLDIR}/lib64

# required for the epiphany gio component to locate the openssl versions of the gio networking
# ARM SUPPORT: make sure you build with the build arg of ARCH set to aarch64
ENV GIO_MODULE_DIR=${INSTALLDIR}/lib/${ARCH}-linux-gnu/gio/modules

# required otherwise dbus-proxy will fail to load. Could be that dbus just isn't properly enabled in the container image
ENV WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1

ENTRYPOINT [ "epiphany" ]
STOPSIGNAL SIGTERM

# Run the container and map the container X envionment to the host X environment
# ipc=host is required because of MIT_SHM extension to X
# docker run -it --rm -e DISPLAY=$DISPLAY --ipc=host -v /tmp/.X11-unix:/tmp/.X11-unix oqs-epiphany
