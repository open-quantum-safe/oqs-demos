#!/bin/bash

if [[ -z "${SERVER_FQDN}" ]]; then
  echo "Running server with default nginx configuration"
  export SERVER_FQDN="nginx"
  echo "hostname: $hostname"
else
  echo "Configuring server for SERVER_FQDN ${SERVER_FQDN}"
  cd /opt
  rm -rf root && mkdir certs
  sed -i "s/nginx/$SERVER_FQDN/g" ext-csr.conf
  python3 genconfig.py $SERVER_FQDN > /tmp/genconfig.log 2>&1 
  cp certs/* /usr/local/nginx/certs && cp oqs-nginx.conf /usr/local/nginx/conf && cp assignments.json /usr/local/nginx/html && cp root/CA.crt /usr/local/nginx/html
fi

echo "CA.crt and assignments.json exposed at http://$SERVER_FQDN:5999"
/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/oqs-nginx.conf -g 'daemon off;' > /usr/local/nginx/logs/stdouterr 2>&1 
#bash
