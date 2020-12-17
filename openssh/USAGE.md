## Purpose 

This is an [opensshd](https://https.openssh.com) docker image based on the [OQS OpenSSH 7.9 fork](https://github.com/open-quantum-safe/openssh), which allows ssh to quantum-safely negotiate session keys and use quantum-safe authentication with algorithms from the [Post-Quantum Cryptography Project by NIST](https://csrc.nist.gov/projects/post-quantum-cryptography).

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities). This is necessary as logging in as root in ssh is not recommended practice. But it is worth to note that this user, per default called `oqs`, is not set as the default user when the image starts (which would be done with `USER oqs` in the [Dockerfile](Dockerfile)). The reason for that is that the the start up script needs root permissions to generate all host keys and start the sshd service. This means that when executing a command as the user `oqs`, the `docker exec` command needs to be used together with the option `--user oqs`.


## Quick start 

How to set up your quantum-safe OpenSSH is described in the corresponding [README.md](README.md).

## Limitations

For limitations of the post-quantum algorithms themselves, refer to [this](https://github.com/open-quantum-safe/openssh#limitations-and-security).

## Slightly more advanced usage options

### Access the man pages of oqs-ssh

Man pages for oqs-ssh are installed in `<INSTALL_DIR>/share/man` and can be viewed by for example 
``` bash
docker run -it --rm openquantumsafe/openssh man -l /opt/oqs-ssh/share/man/man1/ssh.1
```
 or
 ```bash
docker run -it --rm openquantumsafe/openssh man -l /opt/oqs-ssh/share/man/man5/ssh.5
 ```
 Note that those man pages do **not** differ from the original ssh man pages. So it might be easier to consult them on your local system or the internet.

Direct links to man pages: [ssh(1)](https://linux.die.net/man/1/ssh), [sshd(8)](https://linux.die.net/man/8/sshd), [ssh_config(5)](https://linux.die.net/man/5/ssh_config), [sshd_config(5)](https://linux.die.net/man/5/sshd_config)

## Seriously more advanced usage options

### Choosing the algorithms

For a list of all algorithms see [here](https://github.com/open-quantum-safe/openssh#supported-algorithms). It is recommended to only use hybrid algorithms to maintain established classical security. The post-quantum safe algorithms have not yet received enough confidence to be relied on as the only security mechanism.

The image's default key-exchange algorithm is `ecdh-nistp384-kyber-1024-sha384@openquantumsafe.org` for key-exchange with `curve25519-sha256` for backwards compatibility. For host and identity key (authentication) algorithms `ssh-p256-dilithium2` and classical `ssh-ed25519` are used. Those algorithms may be changed by adjusting the files `ssh_config` and `sshd_config` respectively. In the built image, those files are located at the default install location (see above). After changing something in `sshd_config`, the sshd must be restarted using `rc-service oqs-sshd restart`. Alternatively, the configuration can be changed **pre**-build by changing [ssh_config](ssh_config) or [sshd_config](sshd_config) and rebuilding the image.

Be aware that configurations for sshd and for ssh can be different as long as you don't want to connect to localhost. For example can ssh be configured like a classical ssh client and sshd may support post-quantum algorithms only with no backwards compatibility at all.

Note that as long as the backwards compatibility is maintained, the system can not be considered post-quantum safe for obvious reasons.

### Key re-generation

When the image is run without a command, like
```bash
docker run -it openquantumsafe/openssh -t oqs-ssh
```
it generates all host and identity keys that **do not exist** and **are necessary** according to the configuration files ([ssh_config](ssh_config) and [sshd_config](sshd_config)). Their necessity is determinded based on the following parameters:
1. `IdentityFile` for **identity keys**: For every entry (there may be multiple) the corresponding key is generated.
   - e.g. `IdentityFile ~/.ssh/id_ed25519` or
   - `IdentityFile ~/.ssh/id_p256_dilithium2`
2. `HostKeyAlgorithms` for **host keys**: For every algorithm listed a host key will be generated.
   - e.g. `HostKeyAlgorithms ssh-p256-dilithium2,ssh-ed25519`

That to generate the host keys and start the `sshd` the image needs to be run as the `root` user, meaning the `docker run` command shall not contain the `--user oqs` option.

As mentioned above those keys will only be generated if they don't yet exist. So even though the script is executed every time a container is started (or run), it usually only does something the first time. If any host key was generated, the `sshd` service will be restarted.

The location where `key-gen.sh` is looking for `ssh_config`/`sshd_config` is the install directory of `oqs-ssh`.
## Using oqs-ssh for quantum-safe remote access with minimal intrusion

One use case of quantum-safe ssh running in docker could be accessing a remote system without messing with its ssh(d) installation or other parts of the system you maybe don't want to interact with. This means minimal intrusion and everything can easily be removed again. This is done by running this docker image on said system and sharing its network space. Thus it is possible to access host ports from **within** the docker container. Normally, the use case of docker is one of isolation with some shared directories and published ports at max. So this solution works around the usual docker limitations.

Additionally, it is advised to **change the default username and password** when building the image because your plan is to expose it to the world.

```
Structure of quantum-safe remote access using docker containers

+------------------+                +----------------------+
|      Client      |                |         Host         |
|  +------------+  |                |  +----------------+  |
|  |            |  |                |  |                |  |
|  |   Docker   +--------------------=>+     Docker     |  |
|  |            |  |       Port 2222|  |                |  |
|  +------------+  |                |  +-------+--------+  |
|                  |                |          |           |
+------------------+                |  Port 22 v           |
                                    |  +-------+--------+  |
                                    |  |                |  |
                                    |  |  sshd on host  |  |
                                    |  |                |  |
                                    |  +----------------+  |
                                    |                      |
                                    +----------------------+
```
### Set up the server (docker container on target-host)

To start the ssh server, meaning the docker container on the host system, follow those instructions:
- Run the docker image with

       docker run -dit --network host --name oqs-ssh openquantumsafe/openssh

- Or, if you want the container to automatically start with docker

       docker run -dit --network host --name oqs-ssh --restart unless-stopped openquantumsafe/openssh

The `--network host` option will attach the container directly to your host's network, sharing its IP. The sshd in the container is now accessible from the outside using the host's IP address and the specified port (2222 per default).

Be aware that the port 2222 also needs to be open in any firewall's there may be!

If you want to seriously use this image to connect to a machine, it is **strongly advised** to change the default password of the `oqs` user. This can be done in the **running** container either with
```bash
docker exec -it oqs-ssh passwd oqs
```
or you can build the image yourself with a different default password from the sources on [Github](https://github.com/openquantumsafe/oqs-demos).
### Set up the client

For the client side, you run the image with
```bash
docker run -it openquantumsafe/openssh ssh <username>@<remote-host-ip> -p 2222
```
You are then prompted to enter the password for the remote server. Defaults are `oqs` for `<username>` and `oqs.pw` as password. It is strongly adviced to change this password as described above.

You may omit `-p 2222` if this port is configured accordingly in `ssh_config` on the client (which is the default).

And most importantly, we can now access the host's `sshd` from within the docker image by addressing port 22 via the localhost, using the host's credentials.
```bash
ssh <username>@localhost -p 22
```
To omit the `-p 22` option, the specification of the port, this can be set as default in `ssh_config`.

## Further options

### docker run --name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

## List of specific configuration options at a glance

### Port: 2222

Port at which (oqs-)sshd listens by default for quantum-safe ssh connections. Defined/changeable in `sshd_config`.

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
