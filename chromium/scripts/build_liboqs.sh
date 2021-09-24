#!/bin/bash
cd $PROJECT
git clone --branch main https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=$CHROMIUM_ROOT/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF
ninja && ninja install

