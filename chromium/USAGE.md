# OQS-chromium

This file contains usage information for a build of Chromium configured to also support quantum-safe crypto (QSC) operations.

All information to build this from source is contained in the [main subproject README](https://github.com/open-quantum-safe/oqs-demos/tree/main/chromium).

For the unwary user we *strongly* recommend to use a ready-build binary (for x64 Linux) available in the most current [release of oqs-demos](https://github.com/open-quantum-safe/oqs-demos/releases).

## Quick start

1) Execute `./chrome` (or `chrome.exe` in case of a Windows build) in the directory to which oqs-chromium has been built or extracted to.
2) Navigate to [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and [download the current test server certificate](https://test.openquantumsafe.org/CA.crt).
3) Install the certificate in the Chromium certificate store by clicking on "..." in the upper right hand corner , then/-> "Preferences" -> "..." in upper left corner -> "Privacy and Security" -> "Security" -> "Certificate Management" -> "Certification Authorities" -> Import: Load the file "CA.crt" downloaded in step 2.
4) Return to the test server at [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and click any of the supported ports representing all available quantum safe KEM and signature algorithms. A success message is returned if everything works as intended.

Please note that not all algorithm combinations are expected to work. Most notably, none of the X25519 or X448 KEM hybrids are supported by the [underlying integration of OQS-BoringSSL](https://github.com/open-quantum-safe/boringssl).

Please create a [discussion item](https://github.com/open-quantum-safe/boringssl/discussions/landing) if you feel some algorithm combination that does not work should do.


