# Instructions for Building Chromium on Linux

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **$CHROMIUM_ROOT** to refer to the root directory of the Chromium source code.

```shellscript
cd $CHROMIUM_ROOT
git checkout tags/133.0.6943.98
gclient sync
```

### 2. Switch to the OQS-BoringSSL

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master ac42ca1431e487df2247a714d31eb23b926842b1
```

### 3. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use ninja to build liboqs.

```shellscript
git clone https://github.com/open-quantum-safe/liboqs.git && cd liboqs && git checkout f4b96220e4bd208895172acc4fedb5a191d9f5b1
mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=$CHROMIUM_ROOT/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF -DCMAKE_BUILD_TYPE=Release
ninja && ninja install
```

### 4. Enable Quantum-Safe Crypto

```shellscript
cd $CHROMIUM_ROOT
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-Linux.patch
git apply oqs-Linux.patch
```

### 5. Build

```shellscript
cd $CHROMIUM_ROOT
gn args out/Default
```

Then append following lines to the configuration file opened in editor:

```
is_debug = false
symbol_level = 0
enable_nacl = false
blink_symbol_level = 0
```

Save and close the configuration file. Last, run `autoninja -C out/Default chrome`.\
If the build completes successfully, it will create _chrome_ in _$CHROMIUM_ROOT/out/Default_.

### 6. Miscellaneous

- This guide was published on February 16, 2025, and may be outdated.
