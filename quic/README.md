OQS-OpenSSL-QUIC
==================================

[OpenSSL](https://openssl.org/) is an open-source implementation of the TLS protocol and various cryptographic algorithms ([View the original README](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/README).)

OQS-OpenSSL\_1\_1\_1 is a fork of OpenSSL 1.1.1 that adds quantum-safe key exchange and authentication algorithms using [liboqs](https://github.com/open-quantum-safe/liboqs) for prototyping and evaluation purposes. This fork is not endorsed by the OpenSSL project.

This fork: **OQS-OpenSSL-QUIC**, is in turn a fork of OQS-OpenSSL, which adds QUIC protocol support from [quictls](https://github.com/quictls/openssl), a project by Mircosoft and Akamai to add QUIC protocol support to OpenSSL.

A demo for merging OQS-OpenSSL and quictls was originally manually built and [published](https://www.linkedin.com/pulse/quic-protocol-quantum-safe-cryptography-presenting-future-igor/) by [Igor Barshteyn](https://www.linkedin.com/in/igorbarshteyn/).

It was then improved upon by Michael Baentsch of the Open Quantum Safe team to automate the build process (see the **merge-oqs-openssl-quic.sh** shell script in this folder) and to enable further testing of quantum-safe algorithms with the QUIC protocol, resulting in the present fork.

Please [see the original README](https://github.com/open-quantum-safe/openssl#readme) for OQS-OpenSSL for additional information about using and configuring OQS-OpenSSL.

Work to further experiment with the quantum-safe algorithms using the QUIC protocol is ongoing. Questions, comments, corrections, improvements, and other contributions are welcome.

Thanks,

--Igor Barshteyn

## License

All modifications to this repository are released under the same terms as OpenSSL, namely as described in the file [LICENSE](https://github.com/open-quantum-safe/openssl/blob/OQS-OpenSSL_1_1_1-stable/LICENSE).
