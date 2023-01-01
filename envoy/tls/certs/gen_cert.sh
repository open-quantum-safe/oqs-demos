#!/bin/sh

openssl req -x509 -new -newkey dilithium3 -keyout CA_key.pem -out CA_cert.pem -nodes -subj "/CN=localhost" -days 365 #-config /usr/local/openssl/apps/openssl.cnf

openssl req -new -newkey dilithium3 -keyout serverkey.pem -out servercsr.csr -nodes -subj "/CN=localhost" #-config /usr/local/openssl/apps/openssl.cnf

openssl x509 -req -in servercsr.csr -out servercert.pem -CA CA_cert.pem -CAkey CA_key.pem -CAcreateserial -days 365

chown -R $USER *