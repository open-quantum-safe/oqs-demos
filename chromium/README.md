This directory contains no longer fully maintained instructions and corresponding patches to build the Chromium web browser using the [OQS-BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use quantum-safe key exchange algorithms.

These instructions are based on liboqs `0.8.0` and Chromium `117.0.5863.0`; they have been tested only on Windows 10 and Ubuntu 22 LTS(x64) installations and apply at present only to a subset of quantum-safe key-exchanges as [documented here](https://github.com/open-quantum-safe/boringssl#key-exchange).

The information is solely retained for people accepting this limitation. Our focus remains on the support of open source software -- but we do not have the bandwidth to keep supporting the Chromium and BoringSSL PQ software stack at the same level as we did in the past. We welcome contributions and contributors allowing us to change this; most welcome would be contributions to bring up the Linux instructions and [patch](oqs-changes.patch) to the latest up- and downstream code level. 

---

[Build Instructions for Linux](README-Linux.md)

[Build Instructions for Windows](README-Windows.md)
