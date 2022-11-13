
# Usage of the client side container

The post quantum key exchange [openssl](https://github.com/open-quantum-safe/openssl) variant and [getdns](https://getdnsapi.net/) were installed to query the DNS server with a post quantum key exchange algorithm.
## Installation
Assuming you have docker [installed](https://docs.docker.com/install) on your machine all command below will launch dns server docker.

Run getdns container:
```bash
    cd getdns-docker && \
    docker build -t getdns:dev . && \
    docker run --interactive --tty --hostname getdns --name getdns getdns:dev
```
After running all the command above a container will open with getdns running with openssl post quantum variant.

## Usage

In the file [Dockerfile](getdns-docker/Dockerfile#L45) the environment variable  TLS_DEFAULT_GROUPS is set "p384_kyber768:X25519" to force for p384_kyber768 key exchange. Other key exchange algorithms can be used, find more algorithm in the [list of available post quantum key exchange algorithms](https://github.com/open-quantum-safe/boringssl#key-exchange). 

```bash
    ENV TLS_DEFAULT_GROUPS="p384_kyber768:X25519"
```
Or in the interactive container the environment variable can be set with desired key exchange algorithm from the [list](https://github.com/open-quantum-safe/boringssl#key-exchange):
```bash
    export TLS_DEFAULT_GROUPS="p384_kyber768:X25519"
```

To query the DNS server, run the command:

```bash
    getdns_query -s -d example.com A @<DNS server container ip>:853 -L +return_call_reporting
```

By default the DNS server container and the getdns container are connected on the bridge network.
To get the ip address of DNS server container use the command and check the "unbound_pro" ip address:

```bash
    docker network inspect bridge
```
Below is an example output of the command where "unbound_pro" has the ip address of 172.17.0.3.
```json
    "Containers": {
            "4f60737374fc4d90344e8ce3c9d78a926a58f2c5bfd11a5666f9f3172bb258f6": {
                "Name": "getdns",
                "EndpointID": "44e416e9d9eef460035b2153e96a7064922e702e3d1741e681abc16bba2a4f3c",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            },
            "e47733f957c0bb876fd751d1900cbad27db909e43ced9153b47c01d73f3b09a8": {
                "Name": "unbound_pro",
                "EndpointID": "b16a1feed8d5f2c840cf8a9ca9c51c7ada5515cb5b99f5c2254bb8ef46c3710a",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            }
        },

```
After query the DNS server, we can check the key exchange algorithm using wireshark. To verify the key exchange algorithm, use the post quantum [wireshark](https://github.com/open-quantum-safe/oqs-demos/tree/main/wireshark) variant to check the "client hello" package.

![wireshark screenshot](wireshark_screenshot.png)
