## Purpose 

This is an [nginx](https://nginx.org) docker image using OpenSSL3 and the [OQS provider](https://github.com/open-quantum-safe/oqs-provider), which allows `nginx` to negotiate quantum-safe keys and use quantum-safe authentication using TLS 1.3.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/main/nginx), exchange the name of the image from 'openquantumsafe/nginx' in the examples below suitably.

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) such as to allow installation in all types of Kubernetes clusters.

## Quick start 

Assuming Docker is [installed](https://docs.docker.com/install) the following command 

```
docker run -p 4433:4433 openquantumsafe/nginx
```

will start up the QSC-enabled nginx running and listening for quantum-safe crypto protected TLS 1.3 connections on port 4433.

To retrieve a test page, a quantum-safe crypto client program is required. For the most simple use case, use the [docker image for curl](https://hub.docker.com/r/openquantumsafe/curl) with the required quantum-safe crypto enablement. 

If you started the OQS-nginx image on a machine with a registered IP name the required command is simply

```
docker run -it openquantumsafe/curl curl -k https://<ip-name-of-testmachine>:4433
```

If you try this on your local computer, you need to execute both images within one docker network as follows:

```
docker network create nginx-test
docker run --network nginx-test --name oqs-nginx -p 4433:4433 openquantumsafe/nginx
docker run --network nginx-test -it openquantumsafe/curl curl -k https://oqs-nginx:4433
```

## Slightly more advanced usage options

This nginx image supports all quantum-safe key exchange algorithms [presently supported by oqs-provider](https://github.com/open-quantum-safe/oqs-provider#algorithms). If you want to control which algorithm is actually used, you can request one from the list above to the curl command with the '--curves' parameter, e.g., requesting the hybrid Kyber768 variant:

```
docker run -it openquantumsafe/curl curl -k https://oqs-nginx:4433  --curves p384_kyber768
```


## Seriously more advanced usage options

### nginx configuration

If you want to adapt the docker image to your needs you may want to change the nginx configuration file. To facilitate this, you just need to mount your own 'nginx.conf' file into the image at the path `/opt/nginx/nginx-conf`. Assuming you stored your own file `nginx.conf` into a local folder named `nginx-conf` the required command would look like this:

```
docker run -p 4433:4433 --name oqs-nginx -v `pwd`/nginx-conf:/opt/nginx/nginx-conf openquantumsafe/nginx
```

### openssl configuration

Of particular interest is the environment variable `DEFAULT_GROUPS` as it can be used to change the set of the (quantum safe) cryptographic (KEM) algorithms supported by the nginx installation. By default (not setting `DEFAULT_GROUPS`), the plain and hybrid variants of the Kyber family as listed [here](https://github.com/open-quantum-safe/oqs-provider#algorithms) are enabled.

Thus, in order to set up `nginx` to use the `frodo640aes` KEM the following command would do:

    docker run --rm -e DEFAULT_GROUPS=frodo640aes --network nginx-test --name oqs-nginx -p 4433:4433 -it openquantumsafe/nginx

and the following command would test it

    docker run --network nginx-test  -it openquantumsafe/curl curl -k https://oqs-nginx:4433  --curves frodo640aes

within the docker network established above.

### Logfile access

The nginx logfiles are available in the docker-internal folder `/opt/nginx/logs`. Thus, if you want to look at them in the docker host, you can mount them into a local folder named 'nginx-logs' like this:

```
docker run -p 4433:4433 -v `pwd`/nginx-logs:/opt/nginx/logs openquantumsafe/nginx
```

### Validate server certificate

If you look carefully at the curl command above, you will notice the option `-k` which turns off server certificate validation. In the quick start option, this is OK, but if you want to be sure that the set up can actually perform quantum-safe certificate validation, you need to retrieve the CA certificate pre-loaded into the nginx image in order to pass it to the curl command for validation. This is thus a two-step process:

1) Extract CA certificate to local file 'CA.crt': 

    docker run -it openquantumsafe/nginx cat cacert/CA.crt > CA.crt

2) Make this certificate available to curl for verification

    docker run -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://<ip-name-of-testmachine>:4433

*Note*: This command will report a mismatch between the name of your machine and 'oqs-nginx', which is the name of the server built into the demo server certificate. Read below how to rectify this with your own server certificate.

A completely successful call might require the use of a local docker-network where the server name is ensured to match the one encoded in the certificate:

```
docker run --network nginx-test -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://oqs-nginx:4433
```

## Completely standalone deployment

For ease of demonstration, the OQS-nginx image comes with a server and CA certificate preloaded. For a real deployment, the installation of server-specific certificates is required. Also this can be facilitated by mounting your own server key and certificate into the image at the path '/opt/nginx/pki'. Again, assuming server certificate and key are placed in a local folder named `server-pki` the startup command would look like this:

```
docker run -p 4433:4433 -v `pwd`/server-pki:/opt/nginx/pki openquantumsafe/nginx
```


### Creating (test) CA and server certificates

For creating the required keys and certificates, an easy approach is to utilize the [openquantumsafe/curl](https://hub.docker.com/r/openquantumsafe/curl) image using standard `openssl` commands. 

An example sequence is shown below, using 
- 'falcon1024' for signing the CA certificate,
- 'dilithium3' for signing the server certificate,
- 'nginx.server.my.org' as the address of the server for which the certificate is intended.

Instead of 'falcon1024' or 'dilithium3' any of the [quantum safe authentication algorithms presently supported](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be used.

```
# create and enter directory to contain keys and certificates
mkdir -p server-pki && cd server-pki

# create CA key and certificate using qteslapi
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -x509 -new -newkey falcon1024 -keyout /opt/tmp/CA.key -out /opt/tmp/CA.crt -nodes -subj "/CN=oqstest CA" -days 365

# create server key using dilithium3
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -new -newkey dilithium3 -keyout /opt/tmp/server.key -out /opt/tmp/server.csr -nodes -subj "/CN=nginx.server.my.org"

# create server certificate
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl x509 -req -in /opt/tmp/server.csr -out /opt/tmp/server.crt -CA /opt/tmp/CA.crt -CAkey /opt/tmp/CA.key -CAcreateserial -days 365
```

*Note*: You may want to leave away the `-nodes` option to the CA key generation command above to ensure the key is encrypted. You can then safe it for future use at another location.

## Further options

### openssl s_client

You could also use the `openssl s_client` to connect to nginx if you want to follow the protocol more closely. A possible invocation thus would be for example:

```
docker run --network nginx-test -it openquantumsafe/curl openssl s_client -connect oqs-nginx:4433
```

After successful session establishment, issue the command 'GET /' on the resultant command line to retrieve the contents of the nginx root page.

For further options, refer to the [openssl s_client documentation](https://www.openssl.org/docs/manmaster/man1/openssl-s_client.html).

*Note:* Should you fail to see the actual web server contents in the `openssl s_client` output, you may want to add the option `-ign_eof` to the command to see it, i.e., issue this command:

```
docker run --network nginx-test -it openquantumsafe/curl sh -c "echo 'GET /' | openssl s_client -connect oqs-nginx:4433 -ign_eof" 
```


### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option via [--rm](https://docs.docker.com/engine/reference/commandline/run/).

## List of specific configuration options at a glance

### Port: 4433

Port at which nginx listens by default for quantum-safe TLS connections. Defined/changeable in `nginx.conf`.

### nginx logfile folder: /opt/nginx/logs

### nginx configuration file location: /opt/nginx/nginx-conf/nginx.conf

### nginx PKI location: /opt/nginx/pki

#### Server key: /opt/nginx/pki/server.key

#### Server certificate: /opt/nginx/pki/server.crt

#### OQS KEM algorithm list: DEFAULT_GROUPS environment variable

## Putting it all together

If you want to run your own, fully customized quantum safe nginx installation on your machine you can do this with this docker image by running this command (assuming you followed the instructions above for generating your own server keys and certificates).

```
# Ensure UID is properly set for all bind-mounted folders, e.g. like this
rm -rf nginx-logs && mkdir nginx-logs

# Start image with all config folders bind-mounted
docker run --rm --name nginx.server.my.org \
       -p 4433:4433 \
       -v `pwd`/nginx-logs:/opt/nginx/logs \
       -v `pwd`/server-pki:/opt/nginx/pki \
       -v `pwd`/nginx-conf:/opt/nginx/nginx-conf \
       openquantumsafe/nginx
```

Validating that all works as desired can be done by retrieving a document using server validation and this command:

```
# Give curl access to CA certificate via bind-mount
docker run -v `pwd`/server-pki:/opt/tmp -it openquantumsafe/curl \
           curl --cacert /opt/tmp/CA.crt https://nginx.server.my.org:4433
```

Again, if you don't have your own server and want to test on a local machine, start both of them in a docker network (adding the option `--network nginx-test`). 

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
