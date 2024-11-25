This project enables  [Wireshark](https://www.wireshark.org/) to analyze network traffic encrypted with post-quantum
cryptographic protocols
support through the [Open Quantum Safe (OQS) provider](https://github.com/open-quantum-safe/oqs-provider).

## Running Wireshark

You can run the Wireshark Docker container on Linux or Windows using the following command:

```
docker run --rm -it --net=host -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix oqs-wireshark
```

Once Wireshark is running, you can [use it as you normally would](https://www.wireshark.org/docs/),
such as selecting a network interface to capture and analyze traffic.

**Note:** **macOS** support has not been tested yet. We welcome your feedback and suggestions. Please reach us through
the [oqs-demos issue section](https://github.com/open-quantum-safe/oqs-demos/issues).

## Testing quantum-safe Protocols

### 1. Filter by Quantum-Safe Protocols

Use the following Wireshark display filter to isolate quantum-safe TLS traffic:

```
tls && ip.addr == <IP of test.openquantumsafe.org>
```

**Explanation:**
The filter isolates traffic that uses the TLS protocol to or from the specified IP
address. Replace `<IP of test.openquantumsafe.org>` with the resolved IP address (use tools
like `ping` to find the IP).

### 2. Test Quantum-Safe Connections

Run the following command to test a quantum-safe TLS connection:

```
docker run -it openquantumsafe/curl sh -c "curl -k https://test.openquantumsafe.org:6069 --curves kyber1024"
```

**Explanation:**
Replace `6069` with the port number and `kyber1024` with the name of the quantum-safe cryptographic
algorithm you wish to test. Refer to the [Open Quantum Safe test page](https://test.openquantumsafe.org/) for the full
list of supported protocols.