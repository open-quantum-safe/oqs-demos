# Instructions for Building Chromium on Linux

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **$CHROMIUM_ROOT** to refer to the root directory of the Chromium source code.

```shellscript
cd $CHROMIUM_ROOT
git checkout tags/124.0.6339.0
gclient sync
```

### 2. Switch to the OQS-BoringSSL

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout sw-fido2-pqc
```

### 3. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use ninja to build liboqs.

```shellscript
git clone https://github.com/open-quantum-safe/liboqs.git && cd liboqs && git checkout 890a6aa448598a019e72b5431d8ba8e0a5dbcc85
mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=$CHROMIUM_ROOT/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF -DCMAKE_BUILD_TYPE=Release
ninja && ninja install
```

### 4. Enable Quantum-Safe Crypto (TLS and FIDO2)

```shellscript
cd $CHROMIUM_ROOT
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/sw-chromium-fido2/chromium/oqs-Linux.patch
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/sw-chromium-fido2/chromium-fido2/oqs-Linux-fido2.patch
git apply oqs-Linux.patch
git apply oqs-Linux-fido2.patch
```

### 5. Generate BoringSSL Build Files for Chromium

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl
python src/util/generate_build_files.py gn
```

### 6. Build

```shellscript
cd $CHROMIUM_ROOT
gn args out/PQ-FIDO2
```

Then append following lines to the configuration file opened in editor:

```
is_debug = false
symbol_level = 0
enable_nacl = false
blink_symbol_level = 0
```

Save and close the configuration file. Last, run `autoninja -C out/PQ-FIDO2 chrome`.\
If the build completes successfully, it will create _chrome_ in _$CHROMIUM_ROOT/out/PQ-FIDO2_.

### 7. Miscellaneous

- This guide is published on November 4, 2024, and may be outdated.
