This directory contains instructions and corresponding patches to build the Chromium web browser using the [OQS-BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use quantum-safe key exchange algorithms.

Be aware that both cloning the source code as well as building Chromium can take several hours if you do not have excellent network connectivity and serious multicore CPUs at your disposal: The download has a size of over 40GB and even a size-and-performance optimized build (see note below) takes 1143 CPU user minutes on a 2.6GHz i7 CPU, i.e. something like 300 minutes or 5 hours on a quad-core system.

---

## Instructions


- [Build Chromium on Ubuntu](Ubuntu.md)

- [Build Chromium on Windows](Windows.md)