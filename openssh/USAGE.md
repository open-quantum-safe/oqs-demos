# Purpose 

This is an [opensshd](https://https.openssh.com) docker image based on the [OQS OpenSSH 9.7 fork](https://github.com/open-quantum-safe/openssh), which allows ssh to quantum-safely negotiate session keys and use quantum-safe authentication with algorithms from the [Post-Quantum Cryptography Project by NIST](https://csrc.nist.gov/projects/post-quantum-cryptography).

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities). This is necessary as logging in as root in ssh is not recommended practice. But it is worth to note that this user, per default called `oqs`, is not set as the default user when the image starts. The reason for that is that the the start up script needs root permissions to generate all host keys and start the sshd service. This means that when executing a command as the user `oqs`, the `docker exec` command needs to be used together with the option `--user oqs`.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh), exchange the name of the image from 'openquantumsafe/openssh' in the examples below suitably.

# Quick start 

1. Start an OpenSSH server with post-quantum cryptography support by running

        docker run --name oqs-openssh-server -dit --rm openquantumsafe/openssh

2. Connect to that server running

        docker exec --user oqs -it oqs-openssh-server ssh oqs@localhost

3. Accept the host key and authenticate with the default password `Pa55W0rd`

4. To clean up, exit the ssh session with `exit` and run

        docker stop oqs-openssh-server

   to stop (and remove) the container.

*Note:* Due to the `--rm` option the container will be removed as soon as it is stopped, it may be omitted to keep the container. But because we're just testing its basic functionality right now this is not required.
   
# Limitations

For limitations of the post-quantum algorithms themselves, refer to [this](https://github.com/open-quantum-safe/openssh#limitations-and-security).

# Slightly more advanced usage options

## Connect from container to container via OQS-SSH

To easily connect from one container to another, we can make use of the docker's own networking capabilities.

1. Create a docker network with
   
        docker network create oqs-openssh-net

2. Start a new container that is connected to that network with
   
        docker run --rm -dit --net oqs-openssh-net --name oqs-openssh-server openquantumsafe/openssh

3. Then access this server using OQS-SSH through the docker network with
        
        docker run --rm -it --net oqs-openssh-net openquantumsafe/openssh ssh oqs@oqs-openssh-server

   type `yes` to add the host to the `known_hosts` and authenticate the user `oqs` with its default password `Pa55W0rd`.

Congratulations, you just connected from one docker container to another in a quantum safe manner! To use this in a more practical setting, see how to use docker to quantum safely connect to a remote host in section **Using oqs-ssh for quantum safe remote access with minimal intrusion** down below.

## Access the man pages of oqs-ssh

Man pages for oqs-ssh are installed in `<INSTALL_DIR>/share/man` and can be viewed by for example 
```
docker run -it --rm openquantumsafe/openssh man -l /opt/oqs-ssh/share/man/man1/ssh.1
```
or
```
docker run -it --rm openquantumsafe/openssh man -l /opt/oqs-ssh/share/man/man5/ssh.5
 ```
Note that those man pages do **not** differ from the original ssh man pages. So it might be easier to consult them on your local system or the internet.

Direct links to man pages: [ssh(1)](https://linux.die.net/man/1/ssh), [sshd(8)](https://linux.die.net/man/8/sshd), [ssh_config(5)](https://linux.die.net/man/5/ssh_config), [sshd_config(5)](https://linux.die.net/man/5/sshd_config)

## Key-based client authentication

Key-based client authentication works just as it does with normal SSH. Just add your post-quantum public key (normally located in `~/.ssh/*.pub`) to the `authorized_keys` file on the server (normally located in `~/.ssh/authorized_keys`).

## Using oqs-ssh for quantum-safe remote access with minimal intrusion

One use case of quantum-safe ssh running in docker could be accessing a remote system without messing with its ssh(d) installation or other parts of the system you maybe don't want to interact with. This means minimal intrusion and everything can easily be removed again. This is done by running this docker image on said system and sharing its network space. Thus it is possible to access host ports from **within** the docker container. Normally, the use case of docker is one of isolation with some shared directories and published ports at max. So this solution works around the usual docker limitations.

Additionally, it is advised to [change the default username and password](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/README.md#oqs_password) and then building the image yourself because your plan is to expose it to the world.

```
Structure of quantum-safe remote access using docker containers

+------------------+                +----------------------+
|      Client      |                |         Host         |
|  +------------+  |                |  +----------------+  |
|  |            |  |                |  |                |  |
|  |   Docker   +--------------------->+     Docker     |  |
|  |            |  |       Port 2222|  |                |  |
|  +------------+  |                |  +-------+--------+  |
|                  |                |          |           |
+------------------+                |  Port 22 v           |
                                    |  +-------+--------+  |
                                    |  |                |  |
                                    |  |  sshd on Host  |  |
                                    |  |                |  |
                                    |  +----------------+  |
                                    |                      |
                                    +----------------------+
```
### Set up the server (docker container on target host)

To start the ssh server, meaning the docker container on the host system, follow those instructions:
- Run the docker image with

       docker run -dit --network host --name oqs-ssh openquantumsafe/openssh

- Or, if you want the container to automatically start with docker

       docker run -dit --network host --name oqs-ssh --restart unless-stopped openquantumsafe/openssh

The `--network host` option will attach the container directly to your host's network, sharing its IP. The sshd in the container is now accessible from the outside using the host's IP address and the specified port (2222 per default).

Be aware that the port 2222 also needs to be open in any firewalls there may be!

If you want to seriously use this image to connect to a machine, it is **strongly advised** to change the default password of the `oqs` user. This can be done in the **running** container with
```
docker exec -it oqs-ssh passwd oqs
```
Or you build the image yourself with a different default password from the sources on [Github](https://github.com/open-quantum-safe/oqs-demos).

#### Enable classical SSH

Because we want to be able to connect to our host that does not run OQS-SSH, we first need to enable classical SSH capabilities for the client **on the host system**.

1. After running the image, run a shell with `docker exec -it oqs-ssh /bin/bash`

2. Run `nano /opt/oqs-ssh/ssh_config` and 
   - uncomment the line `# IdentityFile ~/.ssh/id_ed25519`,
   - add `ssh-ed25519` to `HostkeyAlgorithms` and `PubkeyAcceptedKeyTypes` (comma-separated)
   - add `curve25519-sha256@libssh.org` to `KexAlgorithms` (comma-separated)

3. Save and exit your editor
4. Run `rc-service oqs-sshd restart`
5. Run `/opt/oqs-ssh/scripts/key-gen.sh`
6. Run `ssh <username>@localhost -p 22` with `<username>` being your host's username to test your setup
7. If everything went smoothly, your docker container connected with your host's classical `sshd`

### Set up the client

For the client side, run the image with
```bash
docker run -it openquantumsafe/openssh ssh <username>@<remote-host-ip> -p 2222
```
You then are prompted to enter the password for the remote server. Defaults are `oqs` for `<username>` and `oqs.pw` as password. It is strongly adviced to change this password as described above.

You may omit `-p 2222` if this port is configured accordingly in `ssh_config` on the client (which is the default).

And most importantly, we can now access the host's `sshd` from within the docker image by addressing port 22 via the localhost, using the host's credentials.
```bash
ssh <username>@localhost -p 22
```
To omit the `-p 22` option, the specification of the port, this can be set as default in `ssh_config`.

# Seriously more advanced usage options

## Configuring `ssh` and `sshd`

If you are using the pre-compiled image from [Dockerhub](https://hub.docker.com/r/openquantumsafe/openssh) you can only make changes to the configuration at run time. Those changes will only be specific to the current container and won't persist through multiple containers and will be lost upon removing the container. The configuration files [ssh_config](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/ssh_config) and [sshd_config](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/sshd_config) are located in `/opt/oqs-ssh/ssh_config` and `/opt/oqs-ssh/sshd_config` respectively. 

If you built the docker image yourself following [these instructions](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh), you can make changes to `ssh_config` and `sshd_config` before building the image (they will be copied to the image at build time). Firstly, this will make your changes the default for your containers and secondly you won't lose them in case you remove the container.

The configuration files can be edited with pre-installed `nano` or `vi` editors, e.g.:
```
docker exec -it <name-or-hash-of-container> nano /opt/oqs-ssh/ssh_config
```
After changing anything in and only in `sshd_config`, run
```
docker exec -it <name-or-hash-of-container> rc-service oqs-sshd restart
```
After adding new `IdentityKey` or `HostKey` values, generate those new keys with
```
docker exec -it <name-or-hash-of-container> /opt/oqs-ssh/scripts/key-gen.sh
```

## Choosing the SIG and KEX algorithms

For a list of all signature and key exchange algorithms see [here](https://github.com/open-quantum-safe/openssh#supported-algorithms). Be aware that there is a limitation of what algorithms are enabled in PQS-OpenSSH per default, more information in the section **Enabling additional PQC algorithms** below. It is recommended to only use the hybrid variants to maintain established classical security. The post-quantum safe algorithms have not yet received enough confidence to be relied on as the only security mechanism.

The image's default key exchange algorithm is `ecdh-nistp384-kyber-768-sha384`. For host and identity keys (server and client authentication, respectively) the `ssh-ecdsa-nistp384-mldsa65` algorithm is used. Those algorithms may be changed by adjusting the files `ssh_config` and `sshd_config` respectively.

**In `ssh_config` (client side)**
- `KexAlgorithms`: Comma-separated list of enabled key-exchange algorithms. Priority given by order. Names according to [this KEX naming scheme](https://github.com/open-quantum-safe/openssh#key-exchange).
- `IdentityKey`: Path to identity key files. One entry for one file, can have multiple entries. SSH will look for those files when connecting to a host. Names of the key files need to be `~/.ssh/id_<SIG>` in order for them to be successfully generated. `<SIG>` is a post-quantum signature algorithm according to [this SIG naming scheme](https://github.com/open-quantum-safe/openssh#digital-signature), with every `-` replaced by `_`. A list with of some possible `IdentityKey` values can be found [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/ssh_config).
- `PubkeyAcceptedKeyTypes`: Comma-separated list of identity keys the client offers to the host. Priority given by order. Note that if no corresponding `IdentityFile` is specified, this algorithm is ignored.
- `HostKeyAlgorithms`: Comma-separated list of the host key types the client accepts from the server. Names according to [this SIG naming scheme](https://github.com/open-quantum-safe/openssh#digital-signature).

**In `sshd_config` (server side)**
- `KexAlgorithms`: Comma-separated list of enabled key-exchange algorithms. Priority given by order. Names according to [this KEX naming scheme](https://github.com/open-quantum-safe/openssh#key-exchange).
- `HostKey`: Path to host key files. One entry for one file, can have multiple entries. SSHD will look for those files when offering a host key to a client. Names of the key files need to be `/opt/oqs-ssh/ssh_host_<SIG>_key` in order for them to be successfully generated. `<SIG>` is a post-quantum signature algorithm according to [this SIG naming scheme](https://github.com/open-quantum-safe/openssh#digital-signature), with every `-` replaced by `_`. A list with of some possible `HostKey` values can be found [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/sshd_config).
- `HostKeyAlgorithms`: Comma-separated list of the host offers to the client. Priority given by order. Note that if no corresponding `HostKey` is specified, this algorithm is ignored. Names according to [this SIG naming scheme](https://github.com/open-quantum-safe/openssh#digital-signature)
- `PubkeyAcceptedKeyTypes`: Comma-separated list of public keys the host will accept from the client.

Be aware that configurations for `sshd` and `ssh` may be entirely different as long as you don't want to connect to `localhost`. For example can `ssh`  be configured like a classical `ssh` client and `sshd` may support post-quantum algorithms only with no backwards compatibility at all.

*Note(s):*
- After changing any of the settings above, don't forget to `rc-service oqs-sshd restart` to apply the changes.
- After adding either a new host or identity key, run `/opt/oqs-ssh/key-gen.sh` to generate the key files as specified. Already existing files won't be altered during this process.
- New keys won't have any effect if they are not configured to be used in `HostKeyAlgorithms` or `PubkeyAcceptedKeyTypes` or if other keys have higher priority (first listed in `HostKeyAlgorithms`/`PubkeyAcceptedKeyTypes` has highest priority).

## Automatic key generation

The generation of the host and identity keys happens via the script [key-gen.sh](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/key-gen.sh) that is executed automatically every time the container started or run. The script checks if the required key already exist and generates it if necessary. This script is called every time the container is started, meaning the first time the container is run (`docker run ...`) and it is started again (`docker start ...`) after a reboot or a `docker stop ...` command. It checks for existing keys before it generates new ones so it will **never** overwrite an already existing key. It also makes sure `sshd` is started after at boot time or is restarted after new host keys were generated.

Which keys to generate is determined using the configuration files (`ssh_config` and `sshd_config`). The need for a specific key is determined based on the following parameters:
1. `IdentityFile` (in `ssh_config`) for **identity keys**: For every entry (there may be multiple) the corresponding identity key is generated.
   - e.g. `IdentityFile ~/.ssh/id_ed25519` or
   - `IdentityFile ~/.ssh/id_ssh-ecdsa-nistp384-mldsa65`
2. `HostKey` (in `sshd_config`) for **host keys**: For every entry (there may be multiple) the corresponding host key is generated.
   - e.g. `HostKey /opt/oqs-ssh/ssh_host_ssh-ecdsa-nistp384-mldsa65_key` or
   - `HostKey /opt/oqs-ssh/ssh_host_ssh-falcon512_key`

In order to generate the host keys and start the `sshd` the image needs to be run as the `root` user, meaning the `docker run` command shall not contain the `--user oqs` option.

As mentioned above, those keys will only be generated if they don't yet exist. So even though the script is executed every time a container is started (or run), it usually only does something the first time. If any host key was generated, the `sshd` service will be restarted.

The location where `key-gen.sh` is looking for `ssh_config`/`sshd_config` is the install directory of `oqs-ssh`, normally `/opt/oqs-ssh/`.

## Enabling additional PQC algorithms

Post-quantum safe algorithms must (in theory) be enabled at docker image build time when compiling [OQS-OpenSSH](https://github.com/open-quantum-safe/openssh). For this reason, in this pre-built image on Dockerhub no more algorithms can be enabled. However, before jumping over to the [build instructions](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh), please continue reading as there is a big BUT.

Long story short: Thus far, no more algorithms may be enabled for this Docker image than described [here](https://github.com/open-quantum-safe/openssh/tree/OQS-OpenSSH-snapshot-2024-08#supported-algorithms). Find out **More details on the why** below.

### More details on the why
It is not quite straight forward how to figure out what PQC algorithms are actually enabled, where to enable them and how. The supported algorithms in release `OQS-OpenSSH-snapshot-2024-08` (the one used when building this Docker image) are listed [in this section](https://github.com/open-quantum-safe/openssh/tree/OQS-OpenSSH-snapshot-2024-08#supported-algorithms). Be especially aware of the limitation for the signature algorithms, where only all L1 signature algorithms and all **Rainbow Classic** variants are enabled by default. **Classic** rainbow only, documentation has it slightly wrong there. This is corrected and clarified in more detail [in newer releases](https://github.com/open-quantum-safe/openssh#digital-signature).

Enabling more algorithms would require changing [openssh/oqs_templates/generate.yml](https://github.com/open-quantum-safe/openssh/blob/OQS-master/oqs-template/generate.yml) according to [this documentation](https://github.com/open-quantum-safe/openssh/wiki/Using-liboqs-supported-algorithms-in-the-fork#code-generation). Additionally, you need to make sure that the algorithms are enabled in [liboqs](https://github.com/open-quantum-safe/liboqs) as well (see [here for more information](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs#oqs_enable_kem_algoqs_enable_sig_alg)). Enabling more algorithms in `liboqs` can be done at Docker build time using the build option `LIBOQS_BUILD_DEFINES`. But enabling them in `OpenSSH` would require changing [openssh/oqs_templates/generate.yml](https://github.com/open-quantum-safe/openssh/blob/OQS-master/oqs-template/generate.yml) after checking out `openssh` in the [Dockerfile](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/Dockerfile), and in this docker image this is just not implemented at this moment in time.

## Compatibility with standard SSH

As this is a demonstration of post-quantum cryptography, backwards compatibility (enabling classical algorithms) is not activated by default. It can be enabled easily by adding the desired classical algorithms in `ssh_config` and `sshd_config`.

To enable classical SSH support on client side, edit/add lines in [ssh_config]([ssh_config](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/ssh_config)) as follows: 

```
KexAlgorithms ecdh-nistp384-kyber-768-sha384@openquantumsafe.org,curve25519-sha256@libssh.org

HostKeyAlgorithms ssh-ecdsa-nistp384-mldsa65,ssh-ed25519

PubkeyAcceptedKeyTypes ssh-ecdsa-nistp384-mldsa65,ssh-ed25519

IdentityFile ~/.ssh/id_ed25519
```

For adding support for classical SSH on server side, edit/add lines in [sshd_config](https://github.com/open-quantum-safe/oqs-demos/tree/main/openssh/sshd_config) as follows:

```
KexAlgorithms ecdh-nistp384-kyber-768-sha384@openquantumsafe.org,curve25519-sha256

HostKeyAlgorithms ssh-ecdsa-nistp384-mldsa65,ssh-ed25519

PubkeyAcceptedKeyTypes ssh-ecdsa-nistp384-mldsa65,ssh-ed25519

HostKey /opt/oqs-ssh/ssh_host_ed25519_key
```

## Further options

### docker run --name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

## List of specific configuration options at a glance

### Port: 2222

Port at which (oqs-)sshd listens for quantum-safe ssh connections. Defined/changeable in `sshd_config`.

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssh#limitations-and-security).
