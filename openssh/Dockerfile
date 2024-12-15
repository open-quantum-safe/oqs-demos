# Multi-stage build: Build components in the first stage

# Define the base versions and tags for dependencies
# Note: Changing LIBOQS_TAG may require updates in sshd_config and ssh_config
ARG ALPINE_VERSION=3.20
ARG LIBOQS_TAG="0.11.0"
ARG OQS_OPENSSH_RELEASE="OQS-v9"

# Define installation directory
ARG DEFAULT_INSTALL_DIR=/opt/oqs-ssh
ARG INSTALL_DIR=${DEFAULT_INSTALL_DIR}

# Define user credentials
ARG OQS_USER="oqs"
ARG OQS_PASSWORD="Pa55W0rd"

FROM alpine:${ALPINE_VERSION} AS intermediate
ARG INSTALL_DIR
ARG LIBOQS_TAG
ARG OQS_OPENSSH_RELEASE
ARG OQS_USER

LABEL version="3"

# Install build dependencies
RUN apk update && apk --no-cache add gcc musl-dev  \
    linux-headers libtool automake autoconf cmake \
    make openssl openssl-dev \
    git docker zlib-dev

# Clone source repositories
WORKDIR /opt
RUN git clone --depth 1 --branch ${LIBOQS_TAG} https://github.com/open-quantum-safe/liboqs && \
    git clone --depth 1 --branch ${OQS_OPENSSH_RELEASE} https://github.com/open-quantum-safe/openssh ossh-src;

# Build and install liboqs
# Note: Shared libraries are not supported; static libraries must be used
WORKDIR /opt/liboqs
RUN cmake .  \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX="/opt/ossh-src/oqs" && \
    make -j"$(nproc)" && make install

# Build and install OQS-OpenSSH
WORKDIR /opt/ossh-src
RUN autoreconf && ./configure \
    --with-libs=-lm \
    --prefix=${INSTALL_DIR} \
    --sysconfdir=${INSTALL_DIR} \
    --with-liboqs-dir=/opt/ossh-src/oqs \
    --with-mantype=man

RUN make -j"$(nproc)" && make install-nokeys

CMD ["sh"]
STOPSIGNAL SIGTERM

# Second stage: Create a minimal image with the built components
FROM alpine:${ALPINE_VERSION} AS dev
ARG DEFAULT_INSTALL_DIR
ARG INSTALL_DIR
ARG OQS_USER
ARG OQS_PASSWORD

# Install runtime tools
RUN apk update && apk --no-cache add bash nano

# Copy installation artifacts from the build stage
COPY --from=intermediate ${INSTALL_DIR} ${INSTALL_DIR}

# Create a system user for SSH
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
RUN addgroup --gid 1000 --system "${OQS_USER}" && \
    adduser --uid 1000 --system "${OQS_USER}" --ingroup "${OQS_USER}" --shell /bin/sh && \
    printf "%s\n%s\n" "${OQS_PASSWORD}" "${OQS_PASSWORD}" | passwd "${OQS_USER}"

# Add SSH binaries to PATH for login shell and ensure /etc/profile executes scripts in /etc/profile.d/
RUN sed -i "s|PATH=|PATH=${INSTALL_DIR}/bin:|;s|/etc/profile.d/\*\.sh|/etc/profile.d/\*|" /etc/profile

# Set up .ssh directory for identity keys
WORKDIR /home/${OQS_USER}/.ssh
RUN chown ${OQS_USER}:${OQS_USER} .

ENV OQS_INSTALL_DIR=${INSTALL_DIR}
ENV OQS_USER=$OQS_USER

# Enable SSH daemon to start at boot
# Note: `rc-service oqs-sshd start` must still be called manually to start the service
COPY oqs-sshd /etc/init.d/
RUN sed -ri "s:${DEFAULT_INSTALL_DIR}:${INSTALL_DIR}:g" /etc/init.d/oqs-sshd
RUN apk --no-cache add openrc openssl \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && rc-update add oqs-sshd \
    && rc-status

# Fix OpenRC cgroup error caused by attempts to modify a read-only file system
RUN sed -ri '269 s/cgroup_add_service/#cgroup_add_service/' /lib/rc/sh/openrc-run.sh

# Copy and configure SSH server settings
COPY sshd_config ${INSTALL_DIR}
RUN sed -ri "s:${DEFAULT_INSTALL_DIR}:${INSTALL_DIR}:g" ${INSTALL_DIR}/sshd_config

# Copy and configure SSH client settings
COPY ssh_config ${INSTALL_DIR}
RUN sed -ri "s:${DEFAULT_INSTALL_DIR}:${INSTALL_DIR}:g" ${INSTALL_DIR}/ssh_config

# Copy utility scripts for server operations
COPY serverstart.sh ${INSTALL_DIR}/test/
COPY connect-test.sh ${INSTALL_DIR}/test/
COPY key-gen.sh ${INSTALL_DIR}/scripts/

# Update PATH for OpenSSH and utility scripts
ENV PATH="${INSTALL_DIR}/bin:${PATH}"
ENV PATH="${INSTALL_DIR}/test:${PATH}"
ENV PATH="${INSTALL_DIR}/scripts:${PATH}"

STOPSIGNAL SIGTERM

# Expose the SSH port for oqs-ssh
EXPOSE 2222

# Prepare entrypoint and default shell
WORKDIR /home/${OQS_USER}/
COPY entrypoint.sh .
RUN chmod a+x ./entrypoint.sh
ENTRYPOINT [ "./entrypoint.sh" ]
CMD [ "/bin/sh" ]
