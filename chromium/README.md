This directory contains no longer fully maintained instructions and corresponding patches to build the Chromium web browser using the [OQS-BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use quantum-safe key exchange algorithms. Note that these instructions have been tested only on Windows 10 installations and apply at present only to a subset of quantum-safe key-exchanges as [documented here](https://github.com/open-quantum-safe/boringssl#key-exchange).

The information is solely retained for people accepting this limitation. This limitation by no means should be understood as a preference for proprietary operating systems by the OQS team: Our focus remains on the support of open source software -- but we do not have the bandwidth to keep supporting the Chromium and BoringSSL PQ software stack at the same level as we did in the past. We welcome contributions and contributors allowing us to change this; most welcome would be contributions to bring up the Linux instructions and [patch](oqs-changes.patch) to the latest up- and downstream code level. 

---

[Untested Build Instructions for Linux](README-Linux.md)

[Build Instructions for Windows](README-Windows.md)
