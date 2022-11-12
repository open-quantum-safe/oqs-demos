
# Unbound(DNS-over-Tls)

This section is intended to implement the post 
quantum key exchange on a DNS server. Two
docker was provided to test the key exchange
between a client and the dns server over a tls connection.

A first docker with unbound configure with dns-over-tls and
using the key exchange of openssl post quantum variant.

A second docker with getdns with openssl post quantum variant 
is used to query the DNS server to test the key exchange.

## Installation
Run Unbound DNS in a docker:
```bash
    cd unbound-docker && \
    sudo docker build -t unbound:dev . && \
    sudo docker run --interactive --publish=853:853 --tty --hostname unbound_pro --name unbound_pro unbound:dev


```
Open another terminal in the folder to run the client docker:
```bash
    cd getdns-docker && \
    sudo docker build -t getdns:dev . && \
    sudo docker run --interactive --tty --hostname getdns --name getdns getdns:dev
```
If you are using the self sign certificate I have provided then
the dns will ask for pass pem. The pass pem is:

```bash
    cyberstorm
```

To query the dns use the client docker and run the command:

```bash
    getdns_query -s -d example.com A @0.0.0.0:853 -L +return_call_reporting
```

Use wireshark to check for key exchange between the client and the DNS server

NOTE: in the client docker(getdns-docker) TLS_DEFAULT_GROUPS is set "p384_kyber768:X25519" to force for p384_kyber768 key exchange.
## Screenshots

![wireshark screenshot](wireshark_screenshot.png)
