oqs-demos snapshot 2023-06 (0.8.0)
==================================

About
-----

The **Open Quantum Safe (OQS) project** has the goal of developing and prototyping quantum-resistant cryptography.  More information on OQS can be found on our website: https://openquantumsafe.org/ and on Github at https://github.com/open-quantum-safe/.

**liboqs** is an open source C library for quantum-resistant cryptographic algorithms.

**open-quantum-safe/oqs-demos** is a collection of integrations of liboqs into various high-level applications requiring the use of cryptography for their core operations.  The goal of this integration is to provide easy prototyping of quantum-resistant cryptography in standard applications. The integrations should not be considered "production quality".

Release notes
=============

This is the 2023-06 release of oqs-demos, which was released on June 26, 2023.  This release is intended to be used with liboqs tag/version `0.8.0`, [oqs-provider](https://github.com/open-quantum-safe/oqs-provider) version `0.5.0`, oqs-openssl tag/version `OQS-OpenSSL_1_1_1-stable snapshot 2023-06`, oqs-boringssl tag/version `OQS-BoringSSL-snapshot-2023-06` and oqs-openssh tag/version `OQS-OpenSSH-snapshot-2023-06`.

This is the final release containing demos utilizing `oqs-openssl111`. Deprecation progress tracked in https://github.com/open-quantum-safe/oqs-demos/issues/182.

What's New
----------

Since the 0.7.2 release (2022-08) the following key changes occurred:

- Added envoy
- Added OpenLiteSpeed
- Added ngtcp2
- Added h2load
- Added unbound
- Removed haproxy
- Upgraded curl, httpd, openvpn, nginx to using OpenSSL3+oqsprovider, replacing oqs-openssl1
- Updated algorithm list to those supported by [liboqs v0.8.0](https://github.com/open-quantum-safe/liboqs/releases/tag/0.8.0)

---

## What's Changed
* nginx config: allow only tls1.2 and tls1.3 on port 443 by @bhess in https://github.com/open-quantum-safe/oqs-demos/pull/157
* Update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/158
* Add ngtcp2 to oqs-demos by @Keelan10 in https://github.com/open-quantum-safe/oqs-demos/pull/159
* adding CI for ngtcp2 by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/160
* doc update pointing to latest chromium image by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/165
* wireshark update [skip ci] by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/166
* Add OpenLiteSpeed to oqs-demos by @Keelan10 in https://github.com/open-quantum-safe/oqs-demos/pull/167
* adding CI for openlitespeed by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/168
* Unbound(DNS-over-tls) with post quantum cryptography by @ryndia in https://github.com/open-quantum-safe/oqs-demos/pull/169
* remove picnic for doc and test by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/172
* Adding code points and OIDs for Dilithium. by @anhu in https://github.com/open-quantum-safe/oqs-demos/pull/170
* adding OQS sigalg code points by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/173
* automatically build and push wireshark demo by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/174
* remove NTRU use by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/178
* OQS Enabled Envoy Contribution by @dr7ana in https://github.com/open-quantum-safe/oqs-demos/pull/161
* remove firesaber from openlitespeed CI test by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/175
* correct oqsprovider location by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/179
* apache upgrade by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/181
* Various upstream updates by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/184
* Change openssh default host key algo to dilithium by @psschwei in https://github.com/open-quantum-safe/oqs-demos/pull/187
* OpenVPN update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/188
* upgrade curl and move to openssl3 by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/190
* Update httpd to OpenSSL3 by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/194
* nginx update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/191
* Fixed httpd demo. by @xvzcf in https://github.com/open-quantum-safe/oqs-demos/pull/198
* Update README.md to fix the cable formatting by @Utopiah in https://github.com/open-quantum-safe/oqs-demos/pull/199
* Add h2load to oqs-demos by @Keelan10 in https://github.com/open-quantum-safe/oqs-demos/pull/196
* Attempt to fix nginx-quic demo. by @xvzcf in https://github.com/open-quantum-safe/oqs-demos/pull/202
* indent fixup for h2load by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/203
* upstream algorithm naming update by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/201
* README update triggering re-build by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/206
* Adds docker build to generate test server package by @bhess in https://github.com/open-quantum-safe/oqs-demos/pull/204
* Revert openvpn base image to debian bullseye by @baentsch in https://github.com/open-quantum-safe/oqs-demos/pull/207

## New Contributors
* @bhess made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/157
* @Keelan10 made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/159
* @ryndia made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/169
* @anhu made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/170
* @dr7ana made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/161
* @psschwei made their first contribution in https://github.com/open-quantum-safe/oqs-demos/pull/187

**Full Changelog**: https://github.com/open-quantum-safe/oqs-demos/compare/0.7.2...0.8.0

