#!/bin/bash

# name of OQS signature algorithm to use for TLS auth key/certs
export OQS_SIGALG="p521_falcon1024"

# name of volume to contain all certs and configs
export OQS_DATA="ovpn-data-oqstest"

# name of docker network to use for testing
export OQS_NETWORK="oqsopenvpntestnet"

# DNS name of test server
export OQS_SERVER="oqsopenvpnserver"

# DNS name of test client
export OQS_CLIENT="oqsopenvpnclient"

# name of docker image to run
export OQS_OPENVPN_DOCKERIMAGE="oqs-openvpn"

if [ ! -z "$1" ]; then
    export OQS_SIGALG=$1
fi

RC=0

echo "Creating test volume $OQS_DATA and test network $OQS_NETWORK"
docker volume create --name $OQS_DATA && docker network create $OQS_NETWORK

if [ $? -ne 0 ]; then
   echo "Could not create volume and network. Exiting."
   exit 1
fi
echo "Test volume $OQS_DATA and test network $OQS_NETWORK created successfully"

# use docker image to create certs and openvpn config
echo "Creating test certs and config"
docker run -e OQSSIGALG=$OQS_SIGALG -e SERVERFQDN=$OQS_SERVER -e CLIENTFQDN=$OQS_CLIENT -v $OQS_DATA:/config/openvpn --rm $OQS_OPENVPN_DOCKERIMAGE sh -c "cd /config/openvpn && createcerts_and_config.sh"

if [ $? -ne 0 ]; then
   echo "Could not create certs and config correctly. Exiting."
   RC=1
fi
echo "Test certs and config created successfully"

echo "Starting test openvpn server and client"
# OQS server & test client:
if [ -z "$2" ]; then
   # use default TLS_GROUPS
   docker run --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN --cap-add=MKNOD --device /dev/net/tun $OQS_OPENVPN_DOCKERIMAGE
   docker run --rm --name $OQS_CLIENT --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn --cap-add=NET_ADMIN --cap-add=MKNOD --device /dev/net/tun -d $OQS_OPENVPN_DOCKERIMAGE clientstart.sh
else
   # assume the first parameter to be (a list of) TLS_GROUPS to be utilized:
   docker run -e TLS_GROUPS=$2 --rm --name $OQS_SERVER --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn -d --cap-add=NET_ADMIN --cap-add=MKNOD --device /dev/net/tun oqs-openvpn
   docker run -e TLS_GROUPS=$2 --rm --name $OQS_CLIENT --net $OQS_NETWORK -v $OQS_DATA:/etc/openvpn --cap-add=NET_ADMIN --cap-add=MKNOD --device /dev/net/tun -d oqs-openvpn clientstart.sh
fi

# Allow time to start up
sleep 3
echo "Startup completed, checking initialization worked OK"
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

# cleanup
docker kill $OQS_SERVER $OQS_CLIENT
docker network rm $OQS_NETWORK
# Allow time to clean data structures
sleep 3
docker volume rm $OQS_DATA
if [ $RC -eq 0 ]; then
   echo "Test completed successfully"
else
   echo "Test failed."
fi
exit $RC
