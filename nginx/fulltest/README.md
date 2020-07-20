# Scripts to generate OQS test server

This folder contains all scripts to [build a QSC-enabled nginx server on ubuntu](build-ubuntu.sh) as well as generating all configuration files for running an interoperability test server: Running [python3 genconfig.py](genconfig.py) generates a local/self-signed root CA, all QSC certificates signed by this root CA for the currently supported list of QSC algorithms and the required nginx-server configuration file for a server running at the configured TESTFQDN server address.

Also provided is a convenience file [package.sh](package.sh) that runs all build steps in one script generating an archive file ready to be deployed at an Ubuntu server.

*Note*: These scripts assume 
- coherent definition of test server FQDN as TESTFQDN in `genconfig.py` and `ext-csr.conf` files: By default "test.openquantumsafe.org" is set.
- presence on the build machine of a writable folder `/opt/nginx` for test-build (and local testing)
- presence on the target deploy server (i.e., at the machine designated at TESTFQDN) of a properly deployed [LetsEncrypt server certificate](https://letsencrypt.org/getting-started).

### HOWTO

On build machine run 

```
./build-ubuntu.sh
./package.sh
scp /opt/nginx/oqs-nginx.tgz yourid@yourserver:yourpath
```

At 'yourserver' run:
```
cd /opt/nginx && tar xzvf yourpath/oqs-nginx.tgz
/opt/nginx/sbin/nginx -c interop.conf
```

*Note*: As the server opens thousands of ports, the server may need to be configured to permit this, e.g., using `ulimit -S -n 4096`.
