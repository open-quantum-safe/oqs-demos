#!/bin/sh

if [ "x$KEM_ALG" != "x" ]; then
   # kem name given, set it
   echo "Setting KEM alg $KEM_ALG"
   sed -i "s/mlkem768/$KEM_ALG/g" /opt/haproxy/conf/haproxy.cfg
fi

cd /opt/haproxy

if [ $# -eq 1 ]; then
   # backend address as sole optional parameter
   echo "Setting target backend $1"
   sed -i "s/127.0.0.1:8181/$1/g" /opt/haproxy/conf/haproxy.cfg 
   # removing backend 2
   sed -i "s/server server2 127\.0\.0\.1\:8182 cookie server2//g" /opt/haproxy/conf/haproxy.cfg
fi

# Start backends:
lighttpd -D -f /etc/lighttpd/lighttpd.conf &
lighttpd -D -f /etc/lighttpd/lighttpd2.conf &

sleep 2

cat pki/server.crt pki/server.key > certkey.pem

# Start HAProxy:
/opt/oqssa/sbin/haproxy -f /opt/haproxy/conf/haproxy.cfg

