
# Usage of the DNS server

[Unbound DNS server](https://github.com/NLnetLabs/unbound) was configured with tls connection using the post quantum [openssl](https://github.com/open-quantum-safe/openssl) variant.
## Installation
Assuming you have docker [installed](https://docs.docker.com/install) on your machine all command below will launch dns server docker.

Run Unbound DNS container:
```bash
    docker network create unbound-test
    docker run --network unbound-test --interactive --publish=853:853 --tty --hostname unbound --name unbound -it openquantumsafe/unbound
```
After running all the command above a container will open with unbound running configure with dns-over-tls and a self signed certificate. 

The key exchange between the server and the client is set on p384_kyber768:X25519, other key exchange algorithms can be used, find more algorithm in the [list of available post quantum key exchange algorithms](https://github.com/open-quantum-safe/boringssl#key-exchange). To specify the desired key exchange algorithm use the parameter `-e` in the `docker run` command.The example below used `kyber1024` to do the key exchange.

```bash
    docker run --network unbound-test -e TLS_DEFAULT_GROUPS=kyber1024 --interactive --publish=853:853 --tty --hostname unbound --name unbound -it openquantumsafe/unbound
```
# DISCLAIMER

[Please check the limitations and security information](https://github.com/open-quantum-safe/openssl#limitations-and-security)
