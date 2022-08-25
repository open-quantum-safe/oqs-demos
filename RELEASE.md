oqs-demos snapshot 2022-08 (0.7.2)
==================================

About
-----

The **Open Quantum Safe (OQS) project** has the goal of developing and prototyping quantum-resistant cryptography.  More information on OQS can be found on our website: https://openquantumsafe.org/ and on Github at https://github.com/open-quantum-safe/.

**liboqs** is an open source C library for quantum-resistant cryptographic algorithms.

**open-quantum-safe/oqs-demos** is a collection of integrations of liboqs into various high-level applications requiring the use of cryptography for their core operations.  The goal of this integration is to provide easy prototyping of quantum-resistant cryptography in standard applications. The integrations should not be considered "production quality".

Release notes
=============

This is the 2022-08 release of oqs-demos, which was released on August 25, 2022.  This release is intended to be used with liboqs tag/version `0.7.2`, oqs-openssl tag/version `OQS-OpenSSL_1_1_1-stable snapshot 2022-08` and oqs-boringssl tag/version `OQS-BoringSSL-snapshot-2022-08`.

What's New
----------

Since the 0.7.1 release (2022-01) the following key changes occurred:

- Added Mosquitto
- Added OpenVPN
- Added Epiphany web browser
- Added QUIC
- Update OpenSSL to version 1.1.1q.
- Remove support for Rainbow level 1 and SIKE/SIDH.
- Adding support for setting default client KEM algorithms in all OpenSSL-based applications via the TLS_DEFAULT_GROUPS environment variable.

---

## What's Changed

* add explicit chromium algorithm listing page by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/118
* Added GNOME Web/epiphany by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/121
* Pull request to add /quic to oqs-demos by @igorbarshteyn in https://github.com/open-quantum-safe/oqs-demos/pull/123
* QUIC docker images by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/124
* remove msquic platform patch by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/127
* Updated chromium tag. by @xvzcf in https://github.com/open-quantum-safe/oqs-demos/pull/128
* remove hybrid sig algs from chromium alg list [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/125
* following msquic upstream update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/130
* upstream change updates by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/132
* Fix duplicated definition of SIG_ALG variable, Dilithium3 by default. by @d1cor in https://github.com/open-quantum-safe/oqs-demos/pull/133
* Pull request to add /mosquitto to oqs-demos by @chiachin2686 in https://github.com/open-quantum-safe/oqs-demos/pull/136
* fix msquic version by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/138
* Adding OpenVPN [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/135
* Adding mosquitto to CI by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/139
* Update quicreach by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/140
* remove sike example use by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/145
* remove nginx setup references to SIKE [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/147
* following upstream dependency update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/148
* improve nginx test server setup documentation [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/149
* doc update [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/151
* Removal of SIKE references by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/154

## New Contributors

* @igorbarshteyn made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/123
* @d1cor made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/133
* @chiachin2686 made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/136

**Full Changelog**: https://github.com/open-quantum-safe/oqs-demos/compare/0.7.1...0.7.2
