## Using the Image

Both the locally built and pre-built images can be used identically to the standard envoy images. For example, when setting a base image for a standard Envoy implementation, one may write

    FROM envoyproxy/envoy-dev:latest

To use the post-quantum image, replace with

    FROM openquantumsafe/envoy:latest

An example implementation of oqs-enabled envoy terminating a tls handshake and proxying to an http backend has been included.