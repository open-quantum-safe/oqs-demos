## Purpose 

This is an [OpenVPN](https://openvpn.net) docker image with the [OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider), which allows openvpn to perform quantum-safe key exchange via TLS 1.3.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/openvpn), exchange the  name of the image from 'openquantumsafe/openvpn' in the examples below suitably.

## Quick start 

Assuming Docker is [installed](https://docs.docker.com/install) the following command 

```
docker run -v $OQS_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN openquantumsafe/openvpn
```

will start up the QSC-enabled openvpn server running and listening for quantum-safe crypto protected TLS 1.3 connections on port 1194.

The docker volume referred-to by the variable `OQS_DATA` needs to be populated with certificates and OpenVPN configuration information as appropriate for the server running the image.

As this requires some scripting already developed for other docker images we did not re-invent the wheel and simply point to such image: By executing

    docker run -v $OQS_DATA:/etc/openvpn --rm kylemanna/openvpn sh -c "ovpn_genconfig -u udp://$OQS_SERVER && EASYRSA_BATCH=1 ovpn_initpki nopass && EASYRSA_BATCH=1 easyrsa build-client-full CLIENTNAME nopass && ovpn_getclient CLIENTNAME > /etc/openvpn/CLIENTNAME.ovpn"

all required information is generated into the docker volume. The variable `OQS_SERVER` must contain the FQDN of the server running the instance.

Additionally, information for connecting to the server is generated into the file `/etc/openvpn/CLIENTNAME.ovpn` and can be used to connect to the server.

If you try this on your local computer, all required steps for installing client and server into a docker image in its own docker network are thus :

```
export OQS_DATA="ovpn-data-oqstest"

export OQS_NETWORK="oqsopenvpntestnet"

export OQS_SERVER="oqsopenvpnserver"

export OQS_CLIENT="oqsopenvpnclient"

docker volume create --name $OQS_DATA
docker network create $OQS_NETWORK

docker run -v $OQS_DATA:/etc/openvpn --rm kylemanna/openvpn sh -c "ovpn_genconfig -u udp://$OQS_SERVER && EASYRSA_BATCH=1 ovpn_initpki nopass && EASYRSA_BATCH=1 easyrsa build-client-full CLIENTNAME nopass && ovpn_getclient CLIENTNAME > /etc/openvpn/CLIENTNAME.ovpn"

docker run --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN openquantumsafe/openvpn 
docker run --rm --name $OQS_CLIENT --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn --cap-add=NET_ADMIN -it openquantumsafe/openvpn clientstart.sh

docker kill $OQS_SERVER $OQS_CLIENT
docker network rm $OQS_NETWORK
docker volume rm $OQS_DATA

```

The last three commands clean up all data structures established.

## Advanced usage options

The docker image has been pre-configured to use the quantum-safe crypto (QSC) algorithm family "Kyber" for key establishment but any plain or hybrid QSC algorithm [supported -- see list here](https://github.com/open-quantum-safe/openssl/tree/OQS-OpenSSL_1_1_1-stable#key-exchange) can be selected. To do so, edit the file(s) `/opt/oqssa/bin/serverstart.sh` and `/opt/oqssa/bin/clientstart.sh` suitably as per the comments in those files. Alternatively, change the value for "Groups" in the OpenSSL configuration file `/opt/oqssa/ssl/openssl.cnf` to reflect the QSC KEM algorithm list to be used.

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).

Most notably, the CA key is not protected by a password and thus accessible to anyone with access to the docker volume.
