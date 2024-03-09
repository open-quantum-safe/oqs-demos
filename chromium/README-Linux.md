# Instructions for Building Chromium on Linux

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **$CHROMIUM_ROOT** to refer to the root directory of the Chromium source code.

```shellscript
cd $CHROMIUM_ROOT
git checkout tags/124.0.6339.0
gclient sync
```

### 2. Install Go and Perl

### 3. Switch to the OQS-BoringSSL

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master c0a0bb4d1243952819b983129c546f9ae1c03008
```

### 4. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use ninja to build liboqs.

```shellscript
git clone --branch main https://github.com/open-quantum-safe/liboqs.git && git checkout 890a6aa448598a019e72b5431d8ba8e0a5dbcc85
cd liboqs && mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=$CHROMIUM_ROOT/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF -DCMAKE_BUILD_TYPE=Release
ninja && ninja install
```

### 5. Enable Quantum-Safe Crypto

```shellscript
cd $CHROMIUM_ROOT
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-Linux.patch
git apply oqs-Linux.patch
```

### 6. Generate BoringSSL Build Files for Chromium

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl
python src/util/generate_build_files.py gn
```

### 7. Build

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

### 8. Miscellaneous

- This guide is published on March 8, 2024, and may be outdated.
