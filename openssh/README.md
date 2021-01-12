## Purpose 

This directory contains a Dockerfile that builds the [OQS OpenSSH fork](https://github.com/open-quantum-safe/openssh), which allows to establish a quantum-safe SSH connection using quantum-safe keys and quantum-safe authentication.

## Quick start

[Install Docker](https://docs.docker.com/install) and run the following commands in this directory:

Make sure to change to the `openssh` directory. The command
```bash
docker build -t oqs-openssh-img .
```
will generate the image with the name `oqs-openssh-img`.

Then running
```bash
docker run --name oqs-openssh-server -ditp 2222:2222 --rm oqs-openssh-img
```
will start a docker container with fresh keys that has `sshd` listening for SSH connections on port 2222 and this port is forwarded to and accessible via `localhost:2222`.

Note that due to the `--rm` option the container will be removed as soon as it is stopped, it may be omitted to keep the container.

With the command
```bash
docker run --rm -it oqs-openssh-img ssh oqs@localhost
```
you run the image and directly connect to it with the user `oqs` and the default password `oqs.pw`. This is not really practical but enough for demonstration purposes.


### Docker permissions

It is possible that the `docker build [...]` command fails with something like `Got permission denied while trying to connect to the Docker daemon socket [...]`. That is because the active user is not a member of the `docker` group yet. To fix this, run
```bash
usermod -aG docker <user>
newgrp docker
```
The first command adds user `<user>` to the group `docker`, and the second simulates a logout/login, so you don't have to do a re-login.

### Connect from container to container via OQS-SSH

1. Make sure two containers of the openssh-img are running. One will be the server and the other one the client. On how to get those containers up and running refer to the [Quick Start](README.md#quick-start) section.

2. Create a docker network with
   
        docker network create oqs-openssh-net

3. Then connect the container with the server running to this network with
        
        docker network connect oqs-openssh-net oqs-openssh-server

4. Now connect from the client to the server with
    
        docker exec -ti oqs-openssh-client ssh oqs@oqs-openssh-server
    
    and authenticate the user `oqs` with its default password `oqs.pw`.

As server and client are based on the same image and both have `sshd` running, connecting from the server to the client's ssh daemon is possible as well. For that use the same commands as above and exchange `server` and `client` accordingly.

## More details

### General information

The Dockerfile 
- obtains all source code required for building the quantum-safe cryptography (QSC) algorithms and the [QSC-enabled version of OpenSSH (7.9-2020-08_p1)](https://github.com/open-quantum-safe/openssh/releases/tag/OQS-OpenSSH-snapshot-2020-08)
- builds all libraries and applications
- by default starts the openssh daemon\*
- creates a second user `oqs` with the default password `oqs.pw`
- by default creates host keys based on the enabled host key algorithms in `sshd_config`\*
- by default creates identity keys based on the config file `ssh_config`\*

\*those steps are executed when the image is started.

**Note for the interested**: The build process is two-stage with the final image only retaining all executables, libraries and include-files to utilize OQS-enabled openssh.

### Key generation

The generation of the host and identity keys happens via the script [key-gen.sh](key-gen.sh) that is called indirectly via the `ENTRYPOINT [ "./entrypoint.sh" ]` command at the end of the [Dockerfile](Dockerfile). The script checks if the required key already exist and gerenates it if necessary. This script is called every time the container is started. It checks for existing keys before it generates them so it will **never** overwrite an already existing key.

### Build type argument(s)

The Dockerfile also facilitates building the underlying OQS library to different specifications (by setting the `--build-arg` variable `LIBOQS_BUILD_DEFINES` as defined [here](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs).

For example, with this build command
```bash
docker build --build-arg LIBOQS_BUILD_DEFINES="-DOQS_USE_CPU_EXTENSIONS=OFF" -f Dockerfile -t oqs-openssh-generic .
``` 
a generic system without processor-specific runtime optimizations is built, thus ensuring execution on all computers (at the cost of maximum runtime performance).

### Updating the liboqs version
Currently the used version of liboqs is [0.4.0](https://github.com/open-quantum-safe/liboqs/releases/tag/0.4.0). Be aware that upon changing this version, which can be done in the [Dockerfile](Dockerfile), the default algorithms may change. If this is the case [sshd_config](sshd_config)/[sshd_config](sshd_config) must be updated accordingly.

### Compatibility with standard SSH

As this is a demonstration of post-quantum cryptography, backwards compatibility (enabling classical algorithms) is not activated by default. It can be enabled easily by adding the desired classical algorithms in ssh_config and sshd_config accordingly, then build the Docker image with those new configuration files.

To enable classical SSH support on client side, edit/add lines in [ssh_config](ssh_config) as follows: 

```
KexAlgorithms ecdh-nistp384-kyber-1024-sha384@openquantumsafe.org,curve25519-sha256@libssh.org

HostKeyAlgorithms ssh-p256-dilithium2,ssh-ed25519

PubkeyAcceptedKeyTypes ssh-p256-dilithium2,ssh-ed25519

IdentityFile ~/.ssh/id_ed25519
```

For adding support for classical SSH on server side, edit/add lines in [sshd_config](sshd_config) as follows:

```
KexAlgorithms ecdh-nistp384-kyber-1024-sha384@openquantumsafe.org,curve25519-sha256

HostKeyAlgorithms ssh-p256-dilithium2,ssh-ed25519

PubkeyAcceptedKeyTypes ssh-p256-dilithium2,ssh-ed25519

HostKey /opt/oqs-ssh/ssh_host_ed25519_key
```

### Enabling more PQC algorithms

Long story short: Thus far, no more algorithms may be enabled for this Docker image than described [here](https://github.com/open-quantum-safe/openssh/tree/OQS-OpenSSH-snapshot-2020-08#supported-algorithms). You can find more details on the why below.

It can be difficult to figure what PQC algorithms are enabled, where you can enable them and how. The supported algorithms in release `OQS-OpenSSH-snapshot-2020-08` (the one used when building this Docker image) are listed [in this section](https://github.com/open-quantum-safe/openssh/tree/OQS-OpenSSH-snapshot-2020-08#supported-algorithms). Be especially aware of the limitation for the signature algorithms, where only all L1 signature algorithms and all **Rainbow Classic** variants are enabled by default (classic only, documentation has it slightly wrong there).

Enabling more algorithms would require changing [openssh/oqs_templates/generate.yml](https://github.com/open-quantum-safe/openssh/blob/OQS-master/oqs-template/generate.yml) according to [this documentation](https://github.com/open-quantum-safe/openssh/wiki/Using-liboqs-supported-algorithms-in-the-fork#code-generation). Additionally, you need to make sure that the algorithms are enabled in [liboqs](https://github.com/open-quantum-safe/liboqs) as well (see [here for more information](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs#oqs_enable_kem_algoqs_enable_sig_alg)). Enabling more algorithms in `liboqs` can be done at Docker build time using the build option `LIBOQS_BUILD_DEFINES`. But enabling them in `OpenSSH` would require changing [openssh/oqs_templates/generate.yml](https://github.com/open-quantum-safe/openssh/blob/OQS-master/oqs-template/generate.yml) after checking out `openssh` in the Dockerfile, and this is not implemented at this moment.

## Usage

More information on how to use the image is [available in the separate file USAGE.md](USAGE.md).

## Build options

The Dockerfile provided allows for some customization of the image built. Those build arguments can be used at buildtime via the flag `--build-arg`, e.g. `docker build --build-arg INSTALL_DIR="/some/directory/" -t myimage .`.

### INSTALL_DIR

This sets the location of the software installation including the configuration files and host keys inside the docker image.

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

### MAKE_INSTALL

This build argument defines the make install target of the OpenSSH installation is defined. Default is `install-nokeys`, so no keys are generated when installing. Another valid value would be `install` which generates keys when installing. Note that this may take quite some time depending on the enabled algorithms, [here you find more information](https://github.com/open-quantum-safe/openssh#supported-algorithms) about what algorithms are enabled by default.

### OQS_USER

Defaults to `oqs`. The docker file creates a non-root user during build. The purpose of this user is to be a login-user for incoming ssh connections. This docker image is designed to be used in a practical way (although not considered production ready, see [Limitations in USAGE.md](USAGE.md#Limitations)), and having root logging in for simply establishing a connection in a production environment is not considered practical.

### OQS_PASSWORD

Defaults to `oqs.pw`. This is the password for the `OQS_USER`. A password is needed to enable the authentication method 'password' for ssh.