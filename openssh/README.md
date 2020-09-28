## Purpose 

This directory contains a Dockerfile that builds the [OQS OpenSSH fork](https://github.com/open-quantum-safe/openssh), which allows to establish a quantum-safe SSH connection using quantum-safe keys and quantum-safe authentication.

## Quick start

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

1. Run `docker build -t oqs-openssh-img .` This will generate the image with the name `oqs-openssh-img`
2. `docker run --name oqs-openssh-server -ditp 2222:2222 --rm oqs-openssh-img`
This will start a docker container that has sshd listening for SSH connections on port 2222 and this port is forwarded to and accessible via `localhost:2222`.
3. `docker run --rm --name oqs-openssh-client -dit oqs-openssh-img` will start a docker container with the same properties as `oqs-openssh-server` except the port 2222 is not published.
4. You can hop on either of those two containers as a non-root user (oqs) to use the built-in OQS-OpenSSH binaries or do other shenanigans by typing
`docker exec -ti -u oqs oqs-openssh-server /bin/sh`
Of course adjust the container's name accordingly if hopping onto the client (==> `oqs-openssh-client`).

It is possible that the `docker build [...]` command fails with something like `Got permission denied while trying to connect to the Docker daemon socket [...]`. That is because the active user is not a member of the `docker` group yet. To fix this run:
```bash
usermod -aG docker <user>
newgrp docker
```
The first command adds user `<user>` to the group `docker`, and the second simulates a logout/login, so you don't have to do a re-login.

### Connect from container to container via OQS-SSH

1. To connect to another docker container, we first need to create a docker network by typing `docker network create oqs-openssh-net`.

1. Then connect the containers to this network by typing `docker network connect oqs-openssh-net <name-of-container>` where `<name-of-container>` is once the server's and once the client's name. Obviously this does not work if the containers are not yet running, in this case refer to the [Quick Start](README.md#quick-start) section.

1. Then connect to the server by typing `docker exec -ti oqs-openssh-client ssh oqs@oqs-openssh-server` and authenticating the user `oqs` with its default password `oqs.pw`.

As server and client are based on the same image, connecting from the server to the client's ssh daemon is possible as well. For that use the same command and exchange `server` and `client`.

## More details

The Dockerfile 
- obtains all source code required for building the quantum-safe cryptography (QSC) algorithms and the [QSC-enabled version of OpenSSH (7.9-2020-08_p1)](https://github.com/open-quantum-safe/openssh/releases/tag/OQS-OpenSSH-snapshot-2020-08)
- builds all libraries and applications
- by default starts the openssh daemon\*
- creates a second user `oqs` with the default password `oqs.pw`
- by default creates host keys based on the enabled host key algorithms in `sshd_config`\*
- by default creates identity keys based on the config file `ssh_config`\*

\*those steps are executed when the image is startet.

**Note for the interested**: The build process is two-stage with the final image only retaining all executables, libraries and include-files to utilize OQS-enabled openssh.

The re-generation of the host and identity keys happens via the script [key-regen.sh](key-regen.sh) that is called with a `CMD` command at the end of the [Dockerfile](Dockerfile). The script checks if the required key already exist and gerenates it if necessary.
#### Build type argument(s)

The Dockerfile also facilitates building the underlying OQS library to different specifications (by setting the `--build-arg` variable `LIBOQS_BUILD_DEFINES` as defined [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

For example, with this build command
```bash
docker build --build-arg LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF" -f Dockerfile -t oqs-openssh-generic .
``` 
a generic system without processor-specific runtime optimizations is built, thus ensuring execution on all computers (at the cost of maximum runtime performance).

## Usage

Information how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for some customization of the image built. Those build arguments can be used at buildtime via the flag `--build-arg`, e.g. `docker build --build-arg INSTALL_DIR="/some/directory/" -t myimage .`.

### INSTALL_DIR

This defines the resultant location of the software installation.

By default this is `/opt/oqs-ssh`. When it is changed, every occurrence of this default path is replaced with it at build time. That means that for example the `ssh_config` file copied to the container can differ from the original [ssh_config](ssh_config) because it is edited during build.

### LIBOQS_BUILD_DEFINES

This permits changing the build options for the underlying library with the quantum safe algorithms. All possible options are documented [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

By default, the image is built such as to have maximum portability regardless of CPU type and optimizations available, i.e. to run on the widest possible range of cloud machines.

### OPENSSH_BUILD_OPTIONS

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
### MAKE_DEFINES

Allow setting parameters to `make` operation, e.g., `-j nnn` where nnn defines the number of jobs run in parallel during build. 

The default is conservative and known not to overload normal machines (default: `-j 2`). If one has a very powerful (many cores, >64GB RAM) machine, passing larger numbers (or only `-j` for maximum parallelism) speeds up the build considerably.

### OQS_USER

Defaults to `oqs`. The docker file creates a non-root user during build. The purpose of this user is to be a login-user for incoming ssh connections. This docker image is designed to be used in a practical way (although not considered production ready, see [Limitations in USAGE.md](USAGE.md#Limitations)), and having root logging in for simply establishing a connection in a production environment is not considered practical.

### OQS_PASSWORD

Defaults to `oqs.pw`. This is the password for the `OQS_USER`. A password is needed to enable the authentication method 'password' for ssh.