 # Define global arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG OPENSSL_PATH=/usr/local/openssl
ARG MAKE_DEFINES="-j 9"					  # 8 virtual cores + 1 manager


FROM ubuntu:20.04 as first_stage


# Take in global arguments
ARG DEBIAN_FRONTEND
ARG OPENSSL_PATH
ARG MAKE_DEFINES


#---------- First installation stage: full build image ----------#



# Build base dependencies - MUST include apt-get update before install -y
RUN apt-get update \
    && apt-get install -y cmake gcc ninja-build libunwind-dev pkg-config python3 python3-pip python3-psutil \
      libtool libssl-dev make git autoconf automake unzip patch virtualenv docker-compose jq wget libpcre3 \
      ninja-build libpcre3-dev zlib1g zlib1g-dev libperl-dev doxygen


# Get sources for /usr/local
WORKDIR /usr/local
RUN git clone --branch main --single-branch --depth 1 https://github.com/open-quantum-safe/liboqs.git liboqs \
    && git clone --branch main --single-branch --depth 1 https://github.com/open-quantum-safe/liboqs.git liboqs-static \
    && git clone --depth 1 --branch OQS-OpenSSL_1_1_1-stable https://github.com/open-quantum-safe/openssl.git \
    && git clone --branch master https://github.com/open-quantum-safe/boringssl.git \
    && git clone https://github.com/Post-Quantum-Mesh/envoy-oqs.git envoy \
    && wget http://www.openssl.org/source/openssl-1.1.1g.tar.gz \
    && tar -zxvf openssl-1.1.1g.tar.gz


# Install latest go version
WORKDIR /usr/local
RUN wget https://go.dev/dl/go1.18.3.linux-amd64.tar.gz \
    && tar -xzf go1.18.3.linux-amd64.tar.gz
ENV PATH="${PATH}:/usr/local/go/bin"


# Install bazelisk as Bazel
WORKDIR /usr/local
RUN wget --no-check-certificate -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64") \
    && chmod +x /usr/local/bin/bazel


# Build OpenSSL
WORKDIR /usr/local/openssl-1.1.1g
RUN ./config \
    && make ${MAKE_DEFINES} \
    && make install


# Build liboqs as static library for openssl
#   - BUILD_SHARED_LIBS - build as static library - default = off
WORKDIR /usr/local/liboqs-static
RUN mkdir build-static \
    && cd build-static \
    && cmake -G"Ninja" \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr/local/openssl/oqs .. \
    && ninja \
    && ninja install


# build openssl-oqs fork
WORKDIR /usr/local/openssl
RUN ./config --openssldir="/usr/local/ssl" \
    && make ${MAKE_DEFINES}

# copy openssl-oqs bin to /usr/local/bin
RUN cp /usr/local/openssl/apps/openssl /usr/local/bin/openssl


# add to path
ENV PATH="${PATH}:/usr/local/bin"


# Build liboqs into boringssl-oqs fork
#   - BUILD_SHARED_LIBS - build as static library - default = off
WORKDIR /usr/local/liboqs
RUN mkdir build \
    && cd build \
    && cmake -G"Ninja" \
      -DCMAKE_INSTALL_PREFIX=/usr/local/boringssl/oqs \
      -DOQS_USE_OPENSSL=OFF .. \
    && ninja \
    && ninja install


# Finish boringssl-liboqs install
WORKDIR /usr/local/boringssl
RUN mkdir build \
    && cd build \
    && cmake -GNinja .. \
    && ninja


# Good stuff
RUN apt-get purge build-essential -y \
    && apt-get autoremove -y


# Get clang-llvm binary
WORKDIR /usr/local
RUN wget --no-check-certificate https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.0/clang+llvm-14.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
    && tar -xf clang+llvm-14.0.0-x86_64-linux-gnu-ubuntu-18.04.tar.xz


# Setup bazel file in envoy src dir
WORKDIR /usr/local/envoy
RUN bazel/setup_clang.sh /usr/local/clang+llvm-14.0.0-x86_64-linux-gnu-ubuntu-18.04
 

# Push build command to user.bazelrc file
WORKDIR /usr/local/envoy
RUN echo "build --config=libc++" >> user.bazelrc


# Build Envoy
WORKDIR /usr/local/envoy
RUN bazel build -c opt envoy


# Add envoy-static to PATH
ENV PATH="${PATH}:/usr/local/envoy/bazel-bin/source/exe"


# Re-name envoy-static to envoy
RUN cp /usr/local/envoy/bazel-bin/source/exe/envoy-static /usr/local/bin/envoy


CMD ["envoy", "--version"]