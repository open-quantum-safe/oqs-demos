This directory contains a Dockerfile that builds curl with the [OQS OpenSSL 1.1.1 fork](https://github.com/open-quantum-safe/openssl), which allows curl to negotiate quantum-safe keys and use quantum-safe authentication in TLS 1.3.

To get started, install Docker and build the image by running `docker build --build-arg SIG_ALG=<SIG> --tag oqs-curl-img .` (`<SIG>` can be any of the authentication algorithms listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms)). Then, in order to verify that the curl so built is capable of using quantum-safe cryptography:

1. Enter the container by running `docker run -it --entrypoint=/bin/bash oqs-curl-img`.

2. Run `/opt/openssl/bin/openssl s_server -cert server.crt -key -server.key -curves <KEX> -www -tls1_3 -accept localhost:4433 &`, where `<KEX>` is a colon-separated list containing any key exchange algorithm listed [here](https://github.com/open-quantum-safe/openssl#supported-algorithms). This starts a basic, post-quantum aware HTTPS web-server.

3. Finally, retrieve a web-page from this server over TLS 1.3 using curl as follows: `/opt/curl/bin/curl --insecure https://localhost:4433/index.html` (the `--insecure` flag is necessary as `s_server` uses self-signed certificates).
