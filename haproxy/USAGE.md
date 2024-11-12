## Purpose

This docker image contains a version of [haproxy](https://www.haproxy.org) configured to also utilize quantum-safe crypto (QSC) operations.

To this end, it contains [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) from the [OpenQuantumSafe](https://openquantumsafe.org) project together with the latest OpenSSL v3 code.

As different images providing the same base functionality may be available, e.g., for debug or performance-optimized operations, the image name `openquantumsafe/haproxy` is consistently used in the description below. Be sure to adapt it to the image you want to use.

This image has a built-in non-root user to permit execution without particular [docker privileges](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) such as to allow installation in all types of Kubernetes clusters.

Also built-in is a backend server whose content is served via the load-balancing features of HAproxy. This is a standard lighttpd without any special configuration settings.

## Quick start

Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run -p 4433:4433 openquantumsafe/haproxy
```

will start up the QSC-enabled haproxy running and listening for quantum-safe crypto protected TLS 1.3 connections on port 4433.

To retrieve a test page, a quantum-safe crypto client program is required. For the most simple use case, use the [docker image for curl](https://hub.docker.com/r/openquantumsafe/curl) with the required quantum-safe crypto enablement.

If you started the OQS-haproxy image on a machine with a registered IP name the required command is simply

```
docker run -it openquantumsafe/curl curl -k https://<ip-name-of-testmachine>:4433
```

If you try this on your local computer, you need to execute both images within one docker network as follows:

```
docker network create haproxy-test
docker run --network haproxy-test --name oqs-haproxy -p 4433:4433 openquantumsafe/haproxy
docker run --network haproxy-test -it openquantumsafe/curl curl -k https://oqs-haproxy:4433
```

## Slightly more advanced usage options

This haproxy image is capable of supporting all quantum-safe key exchange algorithms listed [here](https://github.com/open-quantum-safe/oqs-provider#algorithms). By default the image is built supporting p384_kyber768 and kyber768. You can select a specific curve on the curl command

```
docker run -it openquantumsafe/curl curl -k https://oqs-haproxy:4433 --curves kyber768
```

You can also change the key exchange mechanisms supported by haproxy when you build the image by setting the KEM_ALGLIST build argument


## Seriously more advanced usage options

### haproxy configuration

If you want to adapt the docker image to your needs you may want to change the haproxy configuration file. To facilitate this, you just need to mount your own 'haproxy.cfg' file into the image at the path `/opt/haproxy/conf`. Assuming you stored your own file `haproxy.cfg` into a local folder named `haproxy-conf` the required command would look like this:

```
docker run -p 4433:4433 -v `pwd`/haproxy-conf:/opt/haproxy/conf openquantumsafe/haproxy
```

*Note*: Of particular interest is the `bind` parameter `curves` as it can be used to set the (quantum safe) cryptographic algorithms supported by the haproxy installation. See the example in the 'haproxy.cfg' built into the image and [accessible here](https://github.com/open-quantum-safe/oqs-demos/blob/main/haproxy/conf/haproxy.cfg).

### Validate server certificate

If you look carefully at the curl command above, you will notice the option `-k` which turns off server certificate validation. In the quick start option, this is OK, but if you want to be sure that the set up can actually perform quantum-safe certificate validation, you need to retrieve the CA certificate pre-loaded into the haproxy image in order to pass it to the curl command for validation. This is thus a two-step process:

1) Extract CA certificate to local file 'CA.crt': `docker run -it openquantumsafe/haproxy cat cacert/CA.crt > CA.crt`
2) Make this certificate available to curl for verification

```
docker run -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://<ip-name-of-testmachine>:4433
```

*Note*: This command will report a mismatch between the name of your machine and 'oqs-haproxy', which is the name of the server built into the demo server certificate. Read below how to rectify this with your own server certificate.

A completely successful call requires use of a local docker-network where the server name is ensured to match the one encoded in the certificate:

```
docker run --network haproxy-test -v `pwd`:/opt/cacert -it openquantumsafe/curl curl --cacert /opt/cacert/CA.crt https://oqs-haproxy:4433
```

## Completely standalone deployment

For ease of demonstration, the OQS-haproxy image comes with a server and CA certificate preloaded. For a real deployment, the installation of server-specific certificates is required. Also this can be facilitated by mounting your own server key and certificate into the image at the path '/opt/haproxy/pki'. Again, assuming server certificate and key are placed in a local folder named `server-pki` the startup command would look like this:

```
docker run -p 4433:4433 -v `pwd`/server-pki:/opt/haproxy/pki openquantumsafe/haproxy
```


### Creating (test) CA and server certificates

For creating the required keys and certificates, it is also possible to utilize the [openquantumsafe/curl](https://hub.docker.com/r/openquantumsafe/curl) image using standard `openssl` commands.

An example sequence is shown below, using
- 'qteslapi' for signing the CA certificate,
- 'dilithium2' for signing the server certificate,
- 'haproxy.server.my.org' as the address of the server for which the certificate is intended.

Instead of 'qteslapi' or 'dilithium2' any of the [quantum safe authentication algorithms presently supported](https://github.com/open-quantum-safe/oqs-provider#algorithms) can be used.

```
# create and enter directory to contain keys and certificates
mkdir -p server-pki && cd server-pki

# create CA key and certificate using qteslapi
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -x509 -new -newkey qteslapi -keyout /opt/tmp/CA.key -out /opt/tmp/CA.crt -nodes -subj "/CN=oqstest CA" -days 365

# create server key using dilithium2
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl req -new -newkey dilithium2 -keyout /opt/tmp/server.key -out /opt/tmp/server.csr -nodes -subj "/CN=haproxy.server.my.org"

# create server certificate
docker run -v `pwd`:/opt/tmp -it openquantumsafe/curl openssl x509 -req -in /opt/tmp/server.csr -out /opt/tmp/server.crt -CA /opt/tmp/CA.crt -CAkey /opt/tmp/CA.key -CAcreateserial -days 365
```

*Note*: You may want to leave away the `-nodes` option to the CA key generation command above to ensure the key is encrypted. You can then safe it for future use at another location.

## Further options

The HAproxy configuration contained in the docker image also starts up a statistics UI at port 8484.

### docker -name and --rm options

To ease rapid startup and teardown, we strongly recommend using the docker [--name](https://docs.docker.com/engine/reference/commandline/run/#assign-name-and-allocate-pseudo-tty---name--it) and automatic removal option [--rm](https://docs.docker.com/engine/reference/commandline/run/).

## List of specific configuration options at a glance

### Port: 4433

Port at which haproxy listens by default for quantum-safe TLS connections. Defined/changeable in `haproxy.cfg`.

### Port: 8484

Port at which haproxy listens by default for plain statistics UI requests. Defined/changeable in `haproxy.cfg`.

### haproxy configuration folder location: /opt/haproxy/conf

This folder contains `haproxy.cfg` for baseline haproxy configuration.

### haproxy PKI location: /opt/haproxy/pki

#### Server key: /opt/haproxy/pki/server.key

#### Server certificate: /opt/haproxy/pki/server.crt

## Putting it all together

If you want to run your own, fully customized quantum safe haproxy installation on your machine you can do this with this docker image by running this command (assuming you followed the instructions above for generating your own server keys and certificates).

```

# Start image with all config folders bind-mounted
docker run --rm --name haproxy.server.my.org \
       -p 4433:4433 \
       -p 8484:8484 \
       -v `pwd`/server-pki:/opt/haproxy/pki \
       -v `pwd`/haproxy-conf:/opt/haproxy/conf \
       openquantumsafe/haproxy
```

Validating that all works as desired can be done by retrieving a document using server validation and this command:

```
# Give curl access to CA certificate via bind-mount
docker run -v `pwd`/server-pki:/opt/tmp -it openquantumsafe/curl \
           curl --cacert /opt/tmp/CA.crt https://haproxy.server.my.org:4433
```

Again, if you don't have your own server and want to test on a local machine, start both of them in a docker network (adding the option `--network haproxy-test`).

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTIVE USE](https://github.com/open-quantum-safe/oqs-provider#component-disclaimer).
