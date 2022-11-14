
# Usage of the DNS server

[Unbound DNS server](https://github.com/NLnetLabs/unbound) was configured with tls connection using the post quantum [openssl](https://github.com/open-quantum-safe/openssl) variant.
## Installation
Assuming you have docker [installed](https://docs.docker.com/install) on your machine all command below will launch dns server docker.

Run Unbound DNS container:
```bash
    docker network create unbound-test
    docker run --network unbound-test --interactive --publish=853:853 --tty --hostname unbound --name unbound -it openquantumsafe/unbound
```
After running all the command above a container will open with unbound running configure with dns-over-tls. 
Before running unbound, a certificate is needed. Therefore a self sign certificate will be generate using the [unbound.sh](unbound-docker/unbound.sh) and ask for input.

In the file [unbound.sh](unbound-docker/unbound.sh#L47) the environment variable  TLS_DEFAULT_GROUPS is set "p384_kyber768:X25519" to force for p384_kyber768 key exchange. Other key exchange algorithms can be used, find more algorithm in the [list of available post quantum key exchange algorithms](https://github.com/open-quantum-safe/boringssl#key-exchange). 

```bash
    exec export TLS_DEFAULT_GROUPS="p384_kyber768:X25519"
```
