# NGINX with OQS-BoringSSL for QUIC

This Docker setup provides an nginx instance configured to use OQS-BoringSSL, which supports QUIC with quantum-safe algorithms. For more information on the supported quantum-safe algorithms and how to enable additional algorithms, please refer to the following resources:

- [Supported Algorithms](https://github.com/open-quantum-safe/boringssl?tab=readme-ov-file#supported-algorithms)
- [Using LibOQS Algorithms Not in the Fork](https://github.com/open-quantum-safe/boringssl/wiki/Using-liboqs-algorithms-not-in-the-fork)

## Setup Instructions

### Step 1: Build the Docker Image

Build the Docker image using the provided Dockerfile:

```bash
docker build -t nginx-quic -f Dockerfile-QUIC .
```

### Step 2: Run the Docker Image

To run the image:

- **Without Port Forwarding:**

  ```bash
  docker run -d --name nginx-quic-daemon nginx-quic
  ```

- **With Port Forwarding:**

  ```bash
  docker run -d -p 80:80 -p 443:443 -p 443:443/udp --name nginx-quic-daemon nginx-quic
  ```

### Step 3: Access the Container

To access the container, use:

```bash
docker exec -it nginx-quic-daemon bash
```

Inside the container, nginx configuration files are located in `/etc/nginx`, and the nginx executable is at `/usr/sbin/nginx`.

## Configure NGINX Server Block

Make sure to update `server_name`, `ssl_certificate`, `ssl_certificate_key`, and `ssl_ecdh_curve` according to your specific needs and configuration.

```
    server {
        listen 443 ssl;
        listen 443 quic reuseport;
        listen [::]:443 ssl;
        listen [::]:443 quic reuseport;

        http2 on;
        http3 on;
        ssl_early_data on;
        quic_retry on;
        add_header Alt-Svc 'h3=":443"; ma=86400';

        server_name EXAMPLE.COM;
        ssl_certificate		/PATH/TO/SSL/CERT.PEM;
        ssl_certificate_key	/PATH/TO/SSL/KEY.PEM;

        # Select a subset of supported key exchange algorithms from
        # https://github.com/open-quantum-safe/boringssl?tab=readme-ov-file#key-exchange
        ssl_ecdh_curve 'mlkem1024:bikel3:x25519_frodo640shake';

        location / {
            root   html;
            index  index.html index.htm;
        }

        # OPTIONAL SSL CONFIGURATION
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;
        ssl_session_tickets off;
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;
        add_header Strict-Transport-Security "max-age=63072000" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Content-Type-Options "nosniff" always;
    }
```
