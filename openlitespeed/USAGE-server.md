## Purpose

This is an [OpenLiteSpeed](https://github.com/litespeedtech/openlitespeed) docker image building on [OQS-BoringSSL](https://github.com/open-quantum-safe/boringssl), which allows OpenLiteSpeed to negotiate quantum-safe keys in TLS 1.3.


## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker network create lsws-test
docker run --network lsws-test --name lsws -it openquantumsafe/lsws bash
```

will run the container for the quantum-safe crypto (QSC) protected OpenLiteSpeed server on the docker network called lsws-test.

Run the serverstart.sh script, `/root/serverstart.sh`, to generate certificate and key files and to start the server.

To start the server, run `/usr/local/lsws/bin/lswsctrl start`. For more commands, run `/usr/local/lsws/bin/lswsctrl help`

The document root is  `/usr/local/lsws/Example/html/` 

The CA.crt file is hosted on port 80 and QUIC is enabled on port 443.

### What is WebAdmin Console? 
It is a GUI interface which makes OpenLiteSpeed configuration so much easier. It uses port 7080.

The WebAdmin Console can be accessed through `your-server-ip:7080`
For example `172.17.0.2:7080`
Run `ifconfig` to find your IP address.

To get your WebAdmin Console username and password, run `cat /usr/local/lsws/adminpasswd`
To reset your WebAdmin Console credentials, run `/usr/local/lsws/admin/misc/admpass.sh`


## List of supported key exchange algorithms
[See list of supported quantum-safe key exchange algorithms here](https://github.com/open-quantum-safe/boringssl#key-exchange)



## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/liboqs#limitations-and-security).
