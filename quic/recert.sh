#!/bin/bash

cd /opt

if [ -f "/usr/local/nginx/logs/nginx.pid" ]; then

	kill $(cat /usr/local/nginx/logs/nginx.pid)
fi

if [ -f "/usr/local/nginx/conf/certs/srv.crt" ]; then

	rm /usr/local/nginx/conf/certs/srv.crt
fi

if [ -f "/usr/local/nginx/conf/certs/srv.key" ]; then

	rm /usr/local/nginx/conf/certs/srv.key
fi

if [ -f "CA.crt" ]; then

	rm CA.crt
fi

if [ -f "CA.key" ]; then

	rm CA.key
fi

if [ -f "CA.srl" ]; then

	rm CA.srl
fi

if [ -f "srv.csr" ]; then

	rm srv.csr
fi

read -e -p "Enter the classic, post-quantum, or hybrid signature algorithm for certificates (for initial setup we used default RSA-2048):" -i "rsa:2048" SIGCIPHER

oqs-openssl-quic/apps/openssl req -x509 -new -newkey $SIGCIPHER -keyout CA.key -out CA.crt -nodes -subj "/CN=oqstest CA" -days 365 -config oqs-openssl-quic/apps/openssl.cnf

oqs-openssl-quic/apps/openssl req -new -newkey $SIGCIPHER -keyout srv.key -out srv.csr -nodes -subj "/CN=localhost" -config oqs-openssl-quic/apps/openssl.cnf

oqs-openssl-quic/apps/openssl x509 -req -in srv.csr -out srv.crt -CA CA.crt -CAkey CA.key -CAcreateserial -days 365

mv srv.crt /usr/local/nginx/conf/certs/srv.crt

mv srv.key /usr/local/nginx/conf/certs/srv.key

#echo CA and Server certificates have been regenerated. Please restart the nginx server with sudo /usr/local/nginx/sbin/nginx
/usr/local/nginx/sbin/nginx

