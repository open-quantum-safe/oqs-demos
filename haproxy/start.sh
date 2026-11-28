#!/bin/sh
set -eu

if [ -n "${KEM_ALG:-}" ]; then
   case "$KEM_ALG" in
      *[!A-Za-z0-9_:]*)
         echo "KEM_ALG must be a colon-separated list of group names" >&2
         exit 1
         ;;
   esac
   echo "Setting KEM group $KEM_ALG"
   sed -i "s|curves [^[:space:]]*|curves $KEM_ALG|" /opt/haproxy/conf/haproxy.cfg
fi

cd /opt/haproxy || exit 1

if [ $# -eq 1 ]; then
   # backend address as sole optional parameter
   echo "Setting target backend $1"
   sed -i "s/127.0.0.1:8181/$1/g" /opt/haproxy/conf/haproxy.cfg 
   # removing backend 2
   sed -i "s/server server2 127\.0\.0\.1\:8182 cookie server2//g" /opt/haproxy/conf/haproxy.cfg
fi

# Start backends:
lighttpd -D -f /etc/lighttpd/lighttpd.conf &
backend1=$!
lighttpd -D -f /etc/lighttpd/lighttpd2.conf &
backend2=$!

sleep 2
if ! kill -0 "$backend1" 2>/dev/null || ! kill -0 "$backend2" 2>/dev/null; then
   echo "A lighttpd backend failed to start" >&2
   exit 1
fi

umask 077
certkey_tmp=$(mktemp /opt/haproxy/.certkey.XXXXXX)
cat pki/server.crt pki/server.key > "$certkey_tmp"
mv -f "$certkey_tmp" certkey.pem

# Start HAProxy:
exec /opt/oqssa/sbin/haproxy -f /opt/haproxy/conf/haproxy.cfg

