#!/bin/bash

# Script assumes nginx to have been built for this platform, e.g. using the build-ubuntu.sh script
NGINX_INSTALL_DIR=/opt/nginx

# cleanup: Beware - also kills root CA!
rm -rf *.tgz pki root common.py *.html interop.conf assignments.json

# Obtain current list of algorithms
wget https://raw.githubusercontent.com/open-quantum-safe/openssl/OQS-OpenSSL_1_1_1-stable/oqs-test/common.py

mkdir pki

# Now generate config file, incl. CA and certs
python3 genconfig.py

# Now move all piece-parts in place
rm -rf ${NGINX_INSTALL_DIR}/pki
rm -rf ${NGINX_INSTALL_DIR}/logs/*
cp -R pki ${NGINX_INSTALL_DIR}
cp interop.conf ${NGINX_INSTALL_DIR}
cp index-base.html ${NGINX_INSTALL_DIR}/html
cp root/CA.crt ${NGINX_INSTALL_DIR}/html
cp success.htm ${NGINX_INSTALL_DIR}/html/success.html
cp assignments.json ${NGINX_INSTALL_DIR}/html/

cd ${NGINX_INSTALL_DIR} && tar czvf oqs-nginx.tgz *
set +x
echo "copy ${NGINX_INSTALL_DIR}/oqs-nginx.tgz to server and extract at ${NGINX_INSTALL_DIR}. Start up with '${NGINX_INSTALL_DIR}/sbin/nginx -c interop.conf'"
echo "Possibly raise system wide limits by running  ulimit -S -n 4096 or adding resource extensions like shown for example at https://docs.tigase.net/tigase-server/8.0.0-RC1/Administration_Guide/html_chunk/linuxhighload.html "
