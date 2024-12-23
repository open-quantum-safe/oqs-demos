## Purpose 

This is an [OpenVPN](https://openvpn.net) docker image with the [OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider), which allows openvpn to perform quantum-safe key exchange via TLS 1.3.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/openvpn), exchange the  name of the image from 'openquantumsafe/openvpn' in the examples below suitably.

## Quick start 

Assuming Docker is [installed](https://docs.docker.com/install) the following command 

```
docker run -v $OQS_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN openquantumsafe/openvpn
```

will start up the QSC-enabled openvpn server running and listening for quantum-safe crypto protected TLS 1.3 connections on port 1194.

The docker volume referred-to by the variable `OQS_DATA` needs to be populated with certificates and OpenVPN configuration information as appropriate for setting up a PQ-protected OpenVPN connection.

The required scripting for generating all keys, certificates and configuration files is also contained in the image and can be run as follows:

    docker run -e OQSSIGALG=$OQS_SIGALG -e SERVERFQDN=$OQS_SERVER -e CLIENTFQDN=$OQS_CLIENT -v $OQS_DATA:/config/openvpn --rm openquantumsafe/openvpn sh -c "cd /config/openvpn && createcerts_and_config.sh"

This generates all required configuration information into the docker volume. The mandatory environment variables `SERVERFQDN` and `CLIENTFQDN` must contain the FQDN of the server and the client respectively running the instance. The optional environment variable `OQSSIGALG` may contain the name of any of the [supported OQS PQ signature algorithms](https://github.com/open-quantum-safe/oqs-provider#algorithms); if not set, the default value "mldsa65" is used for creation of client and server keys and certificates.

Additionally, information for connecting to the server is generated into the file `/etc/openvpn/client.config` and can be used to connect to the server.

If you try this on your local computer, all required steps for installing client and server into a docker image in its own docker network are thus :

```
export OQS_DATA="ovpn-data-oqstest"

export OQS_NETWORK="oqsopenvpntestnet"

export OQS_SERVER="oqsopenvpnserver"

export OQS_CLIENT="oqsopenvpnclient"

docker volume create --name $OQS_DATA
docker network create $OQS_NETWORK

docker run -e SERVERFQDN=$OQS_SERVER -e CLIENTFQDN=$OQS_CLIENT -v $OQS_DATA:/config/openvpn --rm openquantumsafe/openvpn sh -c "cd /config/openvpn && createcerts_and_config.sh"

docker run --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN openquantumsafe/openvpn 
docker run --rm --name $OQS_CLIENT --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn --cap-add=NET_ADMIN -it openquantumsafe/openvpn clientstart.sh

docker kill $OQS_SERVER $OQS_CLIENT
docker network rm $OQS_NETWORK
docker volume rm $OQS_DATA

```

The last three commands clean up all data structures established.

## Advanced usage options

The docker image has been pre-configured to use the quantum-safe crypto (QSC) algorithm family "ML-KEM" for key establishment. For TLS1.3 handshaking, the QSC algorithm "mldsa65" is configured by default, but for both algorithm types, any plain or hybrid QSC algorithm can be selected. For the full list of supported OQS KEM and signature algorithms see [here](https://github.com/open-quantum-safe/oqs-provider#algorithms).

### TLS_GROUPS

In order to change the list of algorithms, simply set the environment variable "TLS_GROUPS" to a list of desired algorithms, e.g.:

    docker run -e TLS_GROUPS=p384_frodo976aes:mlkem768 --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN openquantumsafe/openvpn

### OQSSIGALG

In order to change the signature algorithm used for performing the TLS authentication, the environment variable "OQSSIGALG" can be set to trigger creation of the required keys and certificates for the TLS1.3 handshake, e.g.:

    docker run -e OQSSIGALG=p521_mldsa87 -e SERVERFQDN=$OQS_SERVER -e CLIENTFQDN=$OQS_CLIENT -v $OQS_DATA:/config/openvpn --rm openquantumsafe/openvpn sh -c "cd /config/openvpn && createcerts_and_config.sh"

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).

Most notably, the CA key is not protected by a password and thus accessible to anyone with access to the docker volume.
