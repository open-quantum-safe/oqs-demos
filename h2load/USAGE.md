## Purpose 
This directory contains a Dockerfile that builds the [h2load](https://nghttp2.org/documentation/h2load-howto.html) (with support for HTTP/2 and HTTP/3 load testing) using [quictls](https://github.com/quictls/openssl) and [oqs-provider](https://github.com/open-quantum-safe/oqs-provider), which allows h2load to negotiate quantum-safe keys in TLS 1.3.

## Quick start
Assuming Docker is [installed](https://docs.docker.com/install) the following command

```
docker run --network h2load-test --name h2load -it openquantumsafe/h2load
```
will run the container for the PQ-enabled h2load on the docker network called h2load-test (assuming it has already been created. If not, run `docker network create h2load-test`)

### Running Load Tests
After running the h2load container, you can perform HTTP/2 and HTTP/3 load tests. 

For local testing, make sure that the container hosting the test server is on the same network by using the --network flag and --name flag to specify the network and name of the container. For example, you can use the following commands to run OQS-enabled TLS test servers:

```bash
# To run HTTP/2 server
docker run --rm --name oqs-nginx --network h2load-test openquantumsafe/nginx

# To run QUIC server
docker run --ulimit nofile=5000:5000 --rm --network h2load-test --name oqs-nginx-quic -it openquantumsafe/nginx-quic
```


### HTTP/2 Load Test
To perform an HTTP/2 load test, run the following command:
```
h2load -n <num_requests> -c <num_clients> <url> --groups <groups>
```
where <num_requests> is the number of requests to send, <num_clients> is the number of concurrent clients to simulate, and \<url> is the URL to test. 

For example, 
```bash
# Perform basic HTTP/2 load test
h2load -n 1000 -c 10 https://oqs-nginx:4433 --groups kyber512
```

This will send 1000 requests with 10 clients to the oqs-nginx web server on port 4433. The test uses Kyber512 key exchange algorithm. 
If multiple algorithms are selected, they are separated with colons. 
For example, `--groups=kyber512:p256_bikel1`



By default the h2load supports X25519 for key exchange but any plain or hybrid QSC (Quantum-Safe Cryptography) algorithm can be selected. [See list of supported key exchange algorithms here](https://github.com/open-quantum-safe/openssl/tree/OQS-OpenSSL_1_1_1-stable#key-exchange).

To force http/1.1 for both http and https URI, specify `--h1`

### HTTP/3 Load Test

To perform an HTTP/3 load test, run the following command:

```
h2load -n <num_requests> -c <num_clients> <url> --npn-list h3 --groups <groups>
```

For example:
```
h2load -n 1000 -c 10 https://oqs-nginx-quic:6000 --groups kyber512 --npn-list h3
```
This command performs a basic HTTP/3 load test with 1000 requests and 10 clients to the oqs-nginx-quic web server on port 6000, using the Kyber512 key exchange algorithm.


### Timing-based load-testing
This method conducts load testing based on a specified time duration instead of a predetermined number of requests.

To perform timing-based load testing with h2load, use the --duration option followed by the desired duration in seconds. For example, to run a load test for 10 seconds with 100 concurrent clients while limiting the maximum number of streams to 100 per client, use:

```
h2load -c100 --duration=10 --warm-up-time=5 https://oqs-nginx:4433 --groups kyber512
```
For example, 


For more options, run `h2load --help`


More information can be found at https://nghttp2.org/documentation/h2load.1.html

## Disclaimer

[THIS IS NOT FIT FOR PRODUCTION USE](https://github.com/open-quantum-safe/openssl#limitations-and-security).
