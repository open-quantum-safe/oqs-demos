This directory contains no longer fully maintained instructions and corresponding patches to build the Chromium web browser using the [OQS-BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use quantum-safe key exchange algorithms.

These instructions are specifically tailored for liboqs commit `890a6aa448598a019e72b5431d8ba8e0a5dbcc85` and Chromium version `124.0.6339.0`. It is important to note that using any other versions of liboqs or Chromium may result in failure. The instructions have been tested on Windows 10 and Ubuntu 22 LTS(x64) installations only. Additionally, they currently apply to a limited subset of quantum-safe key-exchanges, as detailed in the documentation [provided here](https://github.com/open-quantum-safe/boringssl#key-exchange).

Please be aware that this information is intended for individuals who acknowledge and accept these limitations. While we prioritize support for open source software, we are unable to dedicate the same level of support to the Chromium and BoringSSL PQ software stack as we have in the past. We encourage contributors to update the instructions and patch files for more recent versions of liboqs and Chromium.

---

[Build Instructions for Linux](README-Linux.md)

[Build Instructions for Windows](README-Windows.md)