## Purpose 

This is an [apache httpd](https://httpd.apache.org) docker image using OpenSSL(v3) using [oqs-provider](https://github.com/open-quantum-safe/oqs-provider), which allows httpd to negotiate quantum-safe keys and use quantum-safe authentication using TLS 1.3.

If you built the docker image yourself following the instructions [here](https://github.com/open-quantum-safe/oqs-demos/tree/master/httpd), exchange the  name of the image from 'openquantumsafe/httpd' in the examples below suitably.

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) such as to allow installation in all types of Kubernetes clusters.

## Quick start 

Assuming Docker is [installed](https://docs.docker.com/install) the following command 

```
docker run -p 4433:4433 openquantumsafe/httpd
```

will start up the QSC-enabled httpd running and listening for quantum-safe crypto protected TLS 1.3 connections on port 4433.

To retrieve a test page, a quantum-safe crypto client program is required. For the most simple use case, use the [docker image for curl](https://hub.docker.com/r/openquantumsafe/curl) with the required quantum-safe crypto enablement. 

If you started the OQS-httpd image on a machine with a registered IP name the required command is simply

```
docker run -it openquantumsafe/curl curl -k https://<ip-name-of-testmachine>:4433 --curves kyber768
```

If you try this on your local computer, you need to execute both images within one docker network as follows:

```
docker network create httpd-test
docker run --network httpd-test --name oqs-httpd -p 4433:4433 openquantumsafe/httpd
docker run --network httpd-test -it openquantumsafe/curl curl -k https://oqs-httpd:4433 --curves kyber768
```

## Slightly more advanced usage options

### DEFAULT_GROUPS

This environment variable defines the (quantum-safe) cryptographic KEM algorithms utilized for TLS 1.3 session establishment.

The default value is 'kyber768:p384_kyber768' activating Kyber768 and its hybrid variant for session setup.

Any quantum-safe key exchange algorithm [presently supported by oqs-provider](https://github.com/open-quantum-safe/oqs-provider/#kem-algorithms) may be activated for use. If you want to control which algorithm is actually used, you can request one from the list above you can do this 

- on the server side by setting the environment variable suitably
- on the client side by requesting the algorithm(s) by starting the curl command with the '--curves' parameter, e.g., requesting the weak hybrid Kyber768 variant:

```
docker run --network httpd-test --name oqs-httpd --env DEFAULT_GROUPS=kyber1024:p256_kyber768 openquantumsafe/httpd
docker run --network httpd-test -it openquantumsafe/curl curl -k https://oqs-httpd:4433  --curves p256_kyber768
```

## Seriously more advanced usage options

### httpd configuration

If you want to adapt the docker image to your needs you may want to change the httpd configuration file. To facilitate this, you just need to mount your own 'httpd.conf' file into the image at the path `/opt/httpd/httpd-conf`. Assuming you stored your own file `httpd.conf` into a local folder named `httpd-conf` the required command would look like this:

```
docker run -p 4433:4433 -v `pwd`/httpd-conf:/opt/httpd/httpd-conf openquantumsafe/httpd
```

*Note*: Of particular interest is the parameter `SSLOpenSSLConfCmd Curves` as it can be used to set the (quantum safe) cryptographic algorithms supported by the httpd installation. See the example in the 'httpd.conf' built into the image and [accessible here](https://github.com/open-quantum-safe/oqs-demos/blob/master/httpd/httpd-conf/httpd.conf). An alternative to this option to set the list of permissible KEM algorithms to be used, the underlying OpenSSL configuration logic is set such as to allow even more simple setting of this list via the [DEFAULT_GROUPS](#DEFAULT_GROUPS) environment variable documented above.

### Logfile access

The httpd logfiles are available in the docker-internal folder `/opt/httpd/logs`. Thus, if you want to look at them in the docker host, you can mount them into a local folder named 'httpd-logs' like this:

```
docker run -p 4433:4433 -v `pwd`/httpd-logs:/opt/httpd/logs openquantumsafe/httpd
```

### Validate server certificate

If you look carefully at the curl command above, you will notice the option `-k` which turns off server certificate validation. In the quick start option, this is OK, but if you want to be sure that the set up can actually perform quantum-safe certificate validation, you need to retrieve the CA certificate pre-loaded into the httpd image in order to pass it to the curl command for validation. This is thus a two-step process:

1) Extract CA certificate to local file 'CA.crt': `docker run -it openquantumsafe/httpd cat cacert/CA.crt > CA.crt`
2) Make this certificate available to curl for verification

```
docker run -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://<ip-name-of-testmachine>:4433
```

*Note*: This command will report a mismatch between the name of your machine and 'oqs-httpd', which is the name of the server built into the demo server certificate. Read below how to rectify this with your own server certificate.

A completely successful call requires use of a local docker-network where the server name is ensured to match the one encoded in the certificate:

```
docker run --network httpd-test -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://oqs-httpd:4433 --curves kyber768
```

## Completely standalone deployment

For ease of demonstration, the OQS-httpd image comes with a server and CA certificate preloaded. For a real deployment, the installation of server-specific certificates is required. Also this can be facilitated by mounting your own server key and certificate into the image at the path '/opt/httpd/pki'. Again, assuming server certificate and key are placed in a local folder named `server-pki` the startup command would look like this:

```
docker run -p 4433:4433 -v `pwd`/server-pki:/opt/httpd/pki openquantumsafe/httpd
```


### Creating (test) CA and server certificates

For creating the required keys and certificates, it is also possible to utilize the [openquantumsafe/curl](https://hub.docker.com/r/openquantumsafe/curl) image using standard `openssl` commands. 

An example sequence is shown below, using 
- 'dilithium5' for signing the CA certificate,
- 'dilithium2' for signing the server certificate,
- 'httpd.server.my.org' as the address of the server for which the certificate is intended.

Instead of 'dilithium5' or 'dilithium2' any of the [quantum safe authentication algorithms presently supported](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be used.

```
# create and enter directory to contain keys and certificates
mkdir -p server-pki && cd server-pki

# create CA key and certificate using dilithium5
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -x509 -new -newkey dilithium5 -keyout /opt/tmp/CA.key -out /opt/tmp/CA.crt -nodes -subj "/CN=oqstest CA" -days 365

# create server key using dilithium2
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -new -newkey dilithium2 -keyout /opt/tmp/server.key -out /opt/tmp/server.csr -nodes -subj "/CN=httpd.server.my.org"

# create server certificate
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl x509 -req -in /opt/tmp/server.csr -out /opt/tmp/server.crt -CA /opt/tmp/CA.crt -CAkey /opt/tmp/CA.key -CAcreateserial -days 365
```

*Note*: You may want to leave away the `-nodes` option to the CA key generation command above to ensure the key is encrypted. You can then safe it for future use at another location.

## Further options

### openssl s_client

You could also use the `openssl s_client` to connect to httpd if you want to follow the protocol more closely. A quantum-safe variant of this is also built-in to the [openquantumsafe/curl](https://hub.docker.com/r/openquantumsafe/curl) docker image. A possible invocation thus would be for example:

```
docker run --network httpd-test -it openquantumsafe/curl openssl s_client -connect oqs-httpd:4433
```

After successful session establishment, issue the command 'GET /' on the resultant command line to retrieve the contents of the httpd root page.

For further options, refer to the [openssl s_client documentation](https://www.openssl.org/docs/man1.1.0/man1/openssl-s_client.html).

*Note:* Should you fail to see the actual web server contents in the `openssl s_client` output, you may want to add the option `-ign_eof` to the command to see it, i.e., issue this command:

```
docker run --network httpd-test -it openquantumsafe/curl sh -c "echo 'GET /' | openssl s_client -connect oqs-httpd:4433 -ign_eof" 
```


### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

## List of specific configuration options at a glance

### Port: 4433

Port at which httpd listens by default for quantum-safe TLS connections. Defined/changeable in `httpd.conf`.

### httpd logfile folder: /opt/httpd/logs

### httpd configuration folder location: /opt/httpd/httpd-conf

This folder contains two files: `httpd.conf` for baseline httpd configuration and `httpd-ssl.conf` for all TLS/SSL specific configuration options.

### httpd PKI location: /opt/httpd/pki

#### Server key: /opt/httpd/pki/server.key

#### Server certificate: /opt/httpd/pki/server.crt

## Putting it all together

If you want to run your own, fully customized quantum safe httpd installation on your machine you can do this with this docker image by running this command (assuming you followed the instructions above for generating your own server keys and certificates).

```
# Ensure UID is properly set for all bind-mounted folders, e.g. like this
rm -rf httpd-logs && mkdir httpd-logs

# Start image with all config folders bind-mounted
docker run --rm --name httpd.server.my.org \
       -p 4433:4433 \
       -v `pwd`/httpd-logs:/opt/httpd/logs \
       -v `pwd`/server-pki:/opt/httpd/pki \
       -v `pwd`/httpd-conf:/opt/httpd/httpd-conf \
       openquantumsafe/httpd
```

Validating that all works as desired can be done by retrieving a document using server validation and this command:

```
# Give curl access to CA certificate via bind-mount
docker run -v `pwd`/server-pki:/opt/tmp -it openquantumsafe/curl \
           curl --cacert /opt/tmp/CA.crt https://httpd.server.my.org:4433 --curves kyber768
```

Again, if you don't have your own server and want to test on a local machine, start both of them in a docker network (adding the option `--network httpd-test`). 

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
