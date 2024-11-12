# Purpose 

This directory contains a [Dockerfile](Dockerfile) that builds the [OQS OpenSSH fork](https://github.com/open-quantum-safe/openssh), that allows to establish a quantum safe SSH connection with quantum safe key exchange and authentication.

# Quick start

[Install Docker](https://docs.docker.com/install) and run the following commands:

1. Make sure to change to the `openssh` directory. The command

       docker build -t oqs-openssh-img .

   will build the image with the name `oqs-openssh-img`. Should this command fail with some permission issue, see below for a solution.

2. Start an OpenSSH server with post-quantum cryptography support by running

        docker run --name oqs-openssh-server -dit --rm oqs-openssh-img

3. Connect to that server running

        docker exec --user oqs -it oqs-openssh-server ssh oqs@localhost

4. Accept the host key and authenticate with the default password `Pa55W0rd`

5. To clean up, exit the ssh session with `exit` and run

        docker stop oqs-openssh-server

   to stop (and remove) the container.

*Note:* Due to the `--rm` option the container will be removed as soon as it is stopped, it may be omitted to keep the container. But because we're just testing its basic functionality right now this is not required.

## Docker permission issue

It is possible that the `docker build [...]` command fails with something like `Got permission denied while trying to connect to the Docker daemon socket [...]`. That is because the active user is not a member of the `docker` group yet. To fix this, run
```bash
usermod -aG docker <user>
newgrp docker
```
The first command adds user `<user>` (yourself) to the group `docker`, and the second simulates a logout/login, so you don't have to do a re-login.

# More details

## General information

The Dockerfile 
- obtains all source code required for building the quantum safe cryptography (QSC) algorithms and the [QSC-enabled version of OpenSSH (9.7)](https://github.com/open-quantum-safe/openssh/releases/tag/OQS-OpenSSH-snapshot-2024-08)
- builds all libraries and applications
- creates a second user `oqs` with the default password `Pa55W0rd`
- by default starts the openssh daemon\*
- by default creates host keys based on the config file `sshd_config`\*
- by default creates identity keys based on the config file `ssh_config`\*

\*those steps are executed when the image is started.

**Note for the interested**: The build process is two-stage with the final image only retaining all executables, libraries and include-files to utilize OQS-enabled openssh.

## Updating the liboqs version

Currently the used version of liboqs is [0.11.0](https://github.com/open-quantum-safe/liboqs/releases/tag/0.11.0). Be aware that upon changing this version, which can be done in the [Dockerfile](Dockerfile), the default algorithms may change. If this is the case [sshd_config](sshd_config)/[sshd_config](sshd_config) must be updated accordingly.

# Usage

Detailed information on how to use the image is available in [the separate file USAGE.md](USAGE.md).

# Build options

The Dockerfile provided allows for some customization of the image built. Those build arguments can be used at buildtime via the flag `--build-arg`, e.g. `docker build --build-arg INSTALL_DIR="/some/directory/" -t name-of-image .`.

## LIBOQS_TAG

Tag of `liboqs` release to be used.

## INSTALL_DIR

This sets the location of the software installation including the configuration files and host keys inside the docker image.

By default this is `/opt/oqs-ssh`. When it is changed, every occurrence of this default path is replaced with it at build time. That means that for example the `ssh_config` file copied to the container can differ from the original [ssh_config](ssh_config) because it is edited during build.

## LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/blob/main/CONFIGURE.md).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

## OPENSSH_BUILD_OPTIONS

This allows to configure some additional build options for building OQS-OpenSSH. Those options, if specified, will be appended to the `./configure` command as shown [here](https://github.com/open-quantum-safe/openssh#step-2-build-the-fork). Some parameters are configured as follows in the Dockerfile as they are essential to the build:
```sh
./configure \
    --with-libs=-lm \
    --prefix=${INSTALL_DIR} \
    --sysconfdir=${INSTALL_DIR} \
    --with-liboqs-dir=/opt/ossh-src/oqs \
    --with-mantype=man \
    ${OPENSSH_BUILD_OPTIONS}
```
These parameters will be overridden if specified again in `OPENSSH_BUILD_OPTIONS`.

`/opt/ossh-src/oqs` is the location the intermediate build in the Dockerfile writes the compiled liboqs binaries to. This should not be changed, as it does not influence the final docker image.

## MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., `-j nnn` where `nnn` defines the number of jobs run in parallel during build. 

The default is conservative and known not to overload normal machines (default: `-j 2`). If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only `-j` for maximum parallelism) speeds up the build considerably.

## MAKE_INSTALL

This build argument defines the make install target of the OpenSSH installation is defined. Default is `install-nokeys`, thus no keys are generated when installing. Another valid value would be `install` which generates keys when installing. Note that this may take quite some time depending on the enabled algorithms, [here you find more information](https://github.com/open-quantum-safe/openssh#supported-algorithms) about what algorithms are enabled by default.

**Attention:** Even more importantly, generating the keys at build time would result in all containers spawning from this image having the same host and identity keys, which would mean a severe security risk!

## OQS_USER

Defaults to `oqs`. The docker file creates a non-root user during build. The purpose of this user is to be a login-user for incoming ssh connections. This docker image is designed to be used in a practical way (although not considered production ready, see [Limitations in USAGE.md](USAGE.md#Limitations)), and having root logging in for simply establishing a connection in a production environment is not considered practical.

## OQS_PASSWORD

Defaults to `Pa55W0rd`. This is the password for the `OQS_USER`. A password is needed to enable the authentication method 'password' for ssh.

# Authors

Nico Schwab, Willi Meier, Christoph Wildfeuer (ISE @ FHNW)
