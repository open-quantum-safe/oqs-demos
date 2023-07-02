#!/bin/bash
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master e2d2587065eacfe97aaae940dd43cd964b71f5b4
