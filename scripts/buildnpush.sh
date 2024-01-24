#!/bin/bash

# Helper script to build supported docker images for a specific liboqs/oqsprovider tag/branch and push to docker hub
# It assumes the user has already successfully logged in to the docker hub namespace used

# set to ascertain docker build cache is not used
#export NOCACHE="--no-cache"

# docker hub name space to push images to
export OQS_REPO=openquantumsafe

# docker image tag to set
export RELEASE_TAG=0.9.2

# liboqs release/tag/branch to build
export LIBOQS_TAG=0.9.2
# oqsprovider release/tag/branch to build
export OQSPROVIDER_TAG=0.5.3

cd curl && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/curl:$RELEASE_TAG . && cd ..
cd curl && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG --target dev -t $OQS_REPO/curl-dev:$RELEASE_TAG . && cd ..
cd httpd && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/httpd:$RELEASE_TAG . && cd ..
cd nginx && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/nginx:$RELEASE_TAG . && cd ..
cd openssl3 && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/oqs-openssl3:$RELEASE_TAG . && cd ..
cd openvpn && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/openvpn:$RELEASE_TAG . && cd ..
cd epiphany && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/epiphany:$RELEASE_TAG . && cd ..
cd h2load && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -t $OQS_REPO/h2load:$RELEASE_TAG . && cd ..
cd ngtcp2 && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -f Dockerfile-client -t $OQS_REPO/ngtcp2-client:$RELEASE_TAG . && cd ..
cd ngtcp2 && docker build $NOCACHE --build-arg LIBOQS_TAG=$LIBOQS_TAG --build-arg OQSPROVIDER_TAG=$OQSPROVIDER_TAG -f Dockerfile-server -t $OQS_REPO/ngtcp2-server:$RELEASE_TAG . && cd ..

docker push $OQS_REPO/curl:$RELEASE_TAG && docker push $OQS_REPO/curl-dev:$RELEASE_TAG && docker push $OQS_REPO/httpd:$RELEASE_TAG && docker push $OQS_REPO/nginx:$RELEASE_TAG  && docker push $OQS_REPO/oqs-openssl3:$RELEASE_TAG && docker push $OQS_REPO/openvpn:$RELEASE_TAG && docker push $OQS_REPO/epiphany:$RELEASE_TAG && docker push $OQS_REPO/h2load:$RELEASE_TAG && docker push $OQS_REPO/ngtcp2-client:$RELEASE_TAG && docker push $OQS_REPO/ngtcp2-server:$RELEASE_TAG 
