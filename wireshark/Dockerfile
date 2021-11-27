# Define the wireshark version to be baked in.
ARG WIRESHARK_VERSION=3.4.9

# Define the SSL naming convention: One of "wolfssl" and "oqs"
ARG QSC_SSL_FLAVOR="oqs"

FROM ubuntu as intermediate
ENV DEBIAN_FRONTEND noninteractive

ARG WIRESHARK_VERSION
ARG QSC_SSL_FLAVOR

RUN apt update && apt upgrade -y

# Get all software packages required for building wireshark:
RUN apt install -y gcc g++ \
            libtool \
            automake \
            autoconf \
            cmake \
            ninja-build \
            git \
            curl \
            perl \
            flex \
            bison \
            python \
            python3 \
            libssl-dev \
            libgcrypt-dev \
            libpcap-dev \
            libc-ares-dev \
            qtbase5-dev qttools5-dev-tools qttools5-dev qtmultimedia5-dev \
            wget \
            libssh-dev

# Get the source and unpack it.
WORKDIR /tmp
RUN curl --output wireshark-${WIRESHARK_VERSION}.tar.xz https://2.na.dl.wireshark.org/src/wireshark-${WIRESHARK_VERSION}.tar.xz && tar xmvf wireshark-${WIRESHARK_VERSION}.tar.xz

WORKDIR /tmp/wireshark-${WIRESHARK_VERSION} 

COPY wolfssl-qsc.h wolfssl-qsc.h

# Decide on QSC naming/ID mapping
RUN if [ "x$QSC_SSL_FLAVOR" = "xoqs" ] ; then \
   wget https://raw.githubusercontent.com/open-quantum-safe/openssl/OQS-OpenSSL_1_1_1-stable/qsc.h; \
elif [ "x$QSC_SSL_FLAVOR" = "xwolfssl" ]; then \
   mv wolfssl-qsc.h qsc.h; \
else \
   echo "Unknown naming convention in QSC_SSL_FLAVOR ($QSC_SSL_FLAVOR). Exiting."; \
   exit 1; \
fi

# Patch QSC-specific ids into wireshark code base
RUN cp qsc.h epan/dissectors && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/#include \"config.h\"/#include \"config.h\"\n#include \"qsc.h\"/g" epan/dissectors/packet-tls-utils.c && \
   sed -i "s/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");/oid_add_from_string(\"sha224\", \"2.16.840.1.101.3.4.2.4\");\nQSC_SIGS/g" epan/dissectors/packet-pkcs1.c && \
   sed -i "s/    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\//    { 260\, \"ffdhe8192\" }\, \/\* RFC 7919 \*\/\nQSC_KEMS/g" epan/dissectors/packet-tls-utils.c

# Build wireshark
RUN mkdir -p build && cd build && cmake -GNinja -DCMAKE_INSTALL_PREFIX=/opt/wireshark .. && ninja && ninja install

FROM ubuntu
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y && apt install -y qt5-default libc-ares2 libqt5multimedia5 pcaputils libssh-dev

# Only retain the ${INSTALLDIR} contents in the final image
COPY --from=intermediate /opt/wireshark /opt/wireshark


CMD /opt/wireshark/bin/wireshark
