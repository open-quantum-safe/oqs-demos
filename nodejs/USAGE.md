## Purpose

This directory contains a Dockerfile that builds [NodeJS](https://nodejs.org) with the [OQS OpenSSL 3 provider](https://github.com/open-quantum-safe/oqs-provider), which allows nodejs applications to perform quantum-safe TLS 1.3 handshakes using quantum-safe certificates.

## Quick start
Assuming Docker is [installed](https://docs.docker.com/install), to try out a simple client server application

- Ensure you have cloned this repository and change to the nodejs directory.
- Execute the following to create an interactive docker container which makes the contents of this nodejs directory available to the container so that we can run a nodejs server

```bash
docker run -it --rm -p 6443:8443 --name nodejs-server --entrypoint /bin/bash -v $PWD:/code openquantumsafe/nodejs
# create a CA Root key, certificate and then create the server key and certificate
/code/createcerts.sh
# copy the ca certificate to the code directory so that it is available for the client
cp ca_cert.crt /code
# run the nodejs server
node /code/testserver.js
```

- In another window (again ensuring you are in the nodejs directory of this cloned repository) execute the following to create an interactive container which makes the contents of this nodejs directory available to the container so that we can run a nodejs client. We run this on the host network so we can see the exposed port from the server container

```bash
docker run -it --rm --network host --name nodejs-client --entrypoint /bin/bash -v $PWD:/code openquantumsafe/nodejs
# run the client to show we get a response from the server
node /code/client.js localhost 6443 /hello mlkem768 /code/ca_cert.crt
```

You should see the response from the server being output to the console

```
Hello, World!
```

- Once finished, you should remove the CA certificate stored on your host file system

```bash
rm /code/ca_cert.crt`
```

- You can exit the running containers


## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
