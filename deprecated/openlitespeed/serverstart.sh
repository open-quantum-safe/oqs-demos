#!/bin/bash

# Generate keys and certificates
openssl req -x509 \
-new -newkey rsa:3072 \
-keyout CA.key \
-out CA.crt \
-nodes -subj '/CN=oqstest_CA' -days 500

openssl req \
-new -newkey rsa:3072 \
-keyout srv.key \
-out srv.csr \
-nodes \
-subj '/CN= openlitespeed'

openssl x509 -req \
-in srv.csr \
-out srv.crt \
-CA CA.crt \
-CAkey CA.key \
-CAcreateserial \
-extensions v3_req \
-days 365

cp CA.crt /usr/local/lsws/Example/html/

/usr/local/lsws/bin/lswsctrl start