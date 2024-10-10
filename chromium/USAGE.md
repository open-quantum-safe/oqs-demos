# OQS-chromium

This file contains usage information for a build of Chromium configured to also support quantum-safe crypto (QSC) operations.

All information to build this from source is contained in the [main subproject README](https://github.com/open-quantum-safe/oqs-demos/tree/main/chromium).

For the unwary user we *strongly* recommend to use a ready-build binary (for x64 Linux) available in the most current [release of oqs-demos](https://github.com/open-quantum-safe/oqs-demos/releases).

## Quick start

1) Execute `./chrome` (or `chrome.exe` in case of a Windows build) in the directory to which oqs-chromium has been built or extracted to.
2) Navigate to [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and [download the current test server certificate](https://test.openquantumsafe.org/CA.crt).
3) Install the certificate in the Chromium certificate store by clicking on "..." in the upper right hand corner , then/-> "Preferences" -> "..." in upper left corner -> "Privacy and Security" -> "Security" -> "Certificate Management" -> "Certification Authorities" -> Import: Load the file "CA.crt" downloaded in step 2.
4) Return to the test server at [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and click any of the supported ports representing all available quantum safe KEM and signature algorithms. A success message is returned if everything works as intended.

Please note that not all algorithm combinations are expected to work. Most notably, X448 KEM hybrids and composite signature algorithms are not supported by the [underlying integration of OQS-BoringSSL](https://github.com/open-quantum-safe/boringssl?tab=readme-ov-file#supported-algorithms).

Please create a [discussion item](https://github.com/open-quantum-safe/boringssl/discussions/landing) if you feel some algorithm combination that does not work should do.

## Issues and Workarounds

### Ubuntu/Deb

`ERROR:nsNSSCertificateDB.cpp(95)] PK11_ImportCert failed with error -8168`

There are a few things to try should you recieve this error whilst importing your proxy CA certificate:

1. Manually install CA cert into nssdb.
```sh
# Change permissions to avoid error "read only database"
# chmod -R 766 /home/username/.pki/
# manually invoke certutl
# certutil -d sql:$HOME/.pki/nssdb -A -t "CT,c,c" -n "CertName" -i /usr/share/ca-certificates/your_ca.crt
```
If running this in ansible you may need to replace $HOME with a path to the target users home directory instead of $HOME.

2. Symlink Linux trust store over libnss file (last resort)
```
#backup store
mv /usr/lib/x86_64-linux-gnu/libnssckbi.so /usr/lib/x86_64-linux-gnu/libnssckbi.so.bak
#create symlink
ln -s -f /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-trust.so /usr/lib/x86_64-linux-gnu/libnssckbi.so
```
