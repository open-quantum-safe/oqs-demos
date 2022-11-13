
# Usage of the DNS server

[Unbound DNS server](https://github.com/NLnetLabs/unbound) was configured with tls connection using the post quantum [openssl](https://github.com/open-quantum-safe/openssl) variant.
## Installation
Assuming you have docker [installed](https://docs.docker.com/install) on your machine all command below will launch dns server docker.

Run Unbound DNS container:
```bash
    cd unbound-docker && \
    docker build -t unbound:dev . && \
    docker run --interactive --publish=853:853 --tty --hostname unbound_pro --name unbound_pro unbound:dev
```
After running all the command above a container will open with unbound running configure with dns-over-tls. 

If you are using the self sign certificate I have provided then
the DNS server will ask for a pass pem. The pass pem is:

```bash
    cyberstorm
```
In the file [unbound.sh](https://github.com/ryndia/oqs-demos/blob/main/unbound/unbound-docker/unbound.sh#L47) the environment variable  TLS_DEFAULT_GROUPS is set "p384_kyber768:X25519" to force for p384_kyber768 key exchange. Other key exchange algorithms can be used, find more algorithm in the [list of available post quantum key exchange algorithms](https://github.com/open-quantum-safe/boringssl#key-exchange). 

```bash
    exec export TLS_DEFAULT_GROUPS="p384_kyber768:X25519"
```
