ARG ALPINE_VERSION=3.22
ARG PYTHON_VERSION=3.13
ARG LIBOQS_TAG=0.14.0
ARG LIBOQS_PYTHON_TAG=0.12.0

FROM alpine:${ALPINE_VERSION} AS liboqs-build

ARG LIBOQS_TAG
ARG LIBOQS_PYTHON_TAG

RUN apk update && \
    apk --no-cache add \
        autoconf \
        automake \
        build-base \
        cmake \
        git \
        libtool \
        make \
        ninja \
        openssl \
        openssl-dev

WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs.git && \
    git clone --depth 1 --branch ${LIBOQS_PYTHON_TAG} https://github.com/open-quantum-safe/liboqs-python.git

WORKDIR /opt/liboqs
RUN cmake -G Ninja -B build \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DOQS_ALGS_ENABLED=All \
        -DOQS_BUILD_ONLY_LIB=ON \
        -DOQS_DIST_BUILD=ON \
        -DOQS_USE_OPENSSL=ON \
        -DOQS_DLOPEN_OPENSSL=OFF \
        -DOQS_USE_AES_OPENSSL=ON \
        -DOQS_USE_SHA2_OPENSSL=ON \
        -DOQS_USE_SHA3_OPENSSL=ON \
        -DOQS_OPT_TARGET=x86-64 \
        -DOQS_STRICT_WARNINGS=ON \
        -Wno-dev && \
    ninja -C build

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

COPY --from=liboqs-build /opt/liboqs-python /opt/liboqs-python
COPY --from=liboqs-build /opt/liboqs/build/lib /usr/lib
COPY --from=liboqs-build /opt/liboqs/build/include /usr/include
COPY generate_dataset.py requirements-dataset.txt /

WORKDIR /opt/liboqs-python
RUN pip install --no-cache-dir .

WORKDIR /
RUN pip install --no-cache-dir -r requirements-dataset.txt
RUN mkdir -p /webapp/data

ENV OQS_INSTALL_PATH=/usr
CMD [ "python", "generate_dataset.py" ]
