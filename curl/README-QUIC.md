# cURL with OQS-BoringSSL for QUIC

This Docker setup provides a curl instance configured to use OQS-BoringSSL, which supports QUIC with quantum-safe algorithms. For more information on the supported quantum-safe algorithms and how to enable additional algorithms, please refer to the following resources:

- [Supported Algorithms](https://github.com/open-quantum-safe/boringssl?tab=readme-ov-file#supported-algorithms)
- [Using LibOQS Algorithms Not in the Fork](https://github.com/open-quantum-safe/boringssl/wiki/Using-liboqs-algorithms-not-in-the-fork)

## Setup Instructions

### Step 1: Build the Docker Image

Build the Docker image using the provided Dockerfile:

```bash
docker build -t curl-quic -f Dockerfile-QUIC .
```

### Step 2: Start the Docker Container

To start the container from the Docker image, use the following command:

```bash
docker run -it --name curl-quic-instance curl-quic
```

### Step 3: Use cURL Inside the Container

Once inside the container, you can use the following command to make HTTP/3 requests:

```bash
curl --http3-only https://example.com -curves kex
```

In this command, `kex` represents the key exchange algorithm, such as `mlkem768`.