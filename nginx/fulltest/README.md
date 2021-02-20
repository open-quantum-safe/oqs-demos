# Scripts to generate OQS test server

This folder contains all scripts to [build a QSC-enabled nginx server running on ubuntu](build-ubuntu.sh) as well as generating all configuration files for running an interoperability test server: Running [python3 genconfig.py](genconfig.py) generates a local/self-signed root CA, all QSC certificates signed by this root CA for the currently supported list of QSC algorithms and the required nginx-server configuration file for a server running at the configured TESTFQDN server address.

*Note*: These scripts assume 
- coherent definition of test server FQDN as TESTFQDN in `genconfig.py` and `ext-csr.conf` files: By default "test.openquantumsafe.org" is set.
- presence on the build machine of a writable folder `/opt/nginx` for test-build (and local testing)
- presence on the target deploy server (i.e., at the machine designated at TESTFQDN) of a properly deployed [LetsEncrypt server certificate](https://letsencrypt.org/getting-started).

By default, the server is built to a specific set of versions of `liboqs`, `oqs-openssl` and `nginx`. These versions are encoded in `build-ubuntu.sh` and may be changed/upgraded there.

### HOWTO

#### Option 1: Build and test server separate

On build machine run 

```
./build-ubuntu.sh install
./package.sh
scp /opt/nginx/oqs-nginx.tgz yourid@yourserver:yourpath
```

At 'yourserver' run:
```
cd /opt/nginx && tar xzvf yourpath/oqs-nginx.tgz
/opt/nginx/sbin/nginx -c interop.conf
```

#### Option 2: Building on test server

```
./build-ubuntu.sh install
```

Leave away the `install` option to first do a test-build, e.g., if executed on a live installation.


#### First-time execution

`python3 genconfig.py` generates all required QSC certificates. Execute this at the first installation and/or if/when algorithms supported by liboqs have changed since the last installation. **This script overwrites an existing installation's configuration files. Use with care on a live server.**

#### Activation

Execute `/opt/nginx/sbin/nginx -c /opt/nginx/interop.conf` to start the test server.

*Note*: As the server opens thousands of ports, the server may need to be configured to permit this, e.g., using `ulimit -S -n 4096`.
