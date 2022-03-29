#!/bin/bash

# name of volume to contain all certs and configs
export OQS_DATA="ovpn-data-oqstest"

# name of docker network to use for testing
export OQS_NETWORK="oqsopenvpntestnet"

# name of test server
export OQS_SERVER="oqsopenvpnserver"

# name of test client
export OQS_CLIENT="oqsopenvpnclient"

docker volume create --name $OQS_DATA
docker network create $OQS_NETWORK

# don't re-invent the wheel: Use classic crypto to set up OpenVPN config:
docker run -v $OQS_DATA:/etc/openvpn --rm kylemanna/openvpn sh -c "ovpn_genconfig -u udp://$OQS_SERVER && EASYRSA_BATCH=1 ovpn_initpki nopass && EASYRSA_BATCH=1 easyrsa build-client-full CLIENTNAME nopass && ovpn_getclient CLIENTNAME > /etc/openvpn/CLIENTNAME.ovpn"

## Classic crypto OpenVPN server start:
##docker run -v $OQS_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

# OQS server & test client:
docker run --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN oqs-openvpn 
docker run --rm --name $OQS_CLIENT --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn --cap-add=NET_ADMIN -d oqs-openvpn clientstart.sh

# Check that initialization went OK for both server and client:
docker logs $OQS_SERVER | grep "Initialization Sequence Completed"
if [ $? -ne 0 ]; then
   echo "Error initializing server."
   RC=1
fi
docker logs $OQS_CLIENT | grep "Initialization Sequence Completed"
if [ $? -ne 0 ]; then
   echo "Error initializing client."
   RC=1
fi

docker kill $OQS_SERVER $OQS_CLIENT
docker network rm $OQS_NETWORK
docker volume rm $OQS_DATA
exit $RC
