# NGINX with OQS-BoringSSL for QUIC

This Docker setup provides an nginx instance configured to use OQS-BoringSSL, which supports QUIC with quantum-safe algorithms. For more information on the supported quantum-safe algorithms and how to enable additional algorithms, please refer to the following resources:

- [Supported Algorithms](https://github.com/open-quantum-safe/boringssl?tab=readme-ov-file#supported-algorithms)
- [Using LibOQS Algorithms Not in the Fork](https://github.com/open-quantum-safe/boringssl/wiki/Using-liboqs-algorithms-not-in-the-fork)

## Setup Instructions

### Step 1: Build the Docker Image

Build the Docker image using the provided Dockerfile:

```bash
docker build -f Dockerfile-QUIC .
```

After building, remember the SHA256 hash of the image from the last line of the output.

### Step 2: Run the Docker Image

To run the image:

- **Without Port Forwarding:**

  ```bash
  docker run -d SHA256_OF_THE_IMAGE
  ```

- **With Port Forwarding:**

  ```bash
  docker run -d -p 80:80 -p 443:443 -p 443:443/udp SHA256_OF_THE_IMAGE
  ```

Replace `SHA256_OF_THE_IMAGE` with the actual SHA256 hash of the Docker image.

### Step 3: Find the Container ID

To find the container ID, use:

```bash
docker ps
```

### Step 4: Access the Container

To access the container, use:

```bash
docker exec -it CONTAINER_ID bash
```

Replace `CONTAINER_ID` with the ID obtained from the previous step.

Inside the container, nginx configuration files are located in `/etc/nginx`, and the nginx executable is at `/usr/sbin/nginx`.
