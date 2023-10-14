# Instructions for Building Chromium on Linux

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **$CHROMIUM_ROOT** to refer to the root directory of the Chromium source code.

### 2. Install Go and Perl

### 3. Switch to the OQS-BoringSSL

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master 1ca41b49e9198f510991fb4f350b4a5fd4c1d5ff
```

### 4. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use ninja to build liboqs.

```shellscript
git clone --branch main https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=$CHROMIUM_ROOT/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF
ninja && ninja install
```

### 5. Enable Quantum-Safe Crypto

```shellscript
cd $CHROMIUM_ROOT
wget https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-changes.patch
git apply oqs-changes.patch
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

- This guide is published on July 1, 2023, and may be outdated.
- A certificate chain that includes quantum-safe signatures can only be validated if it terminates with a root certificate that is in the [Chrome Root Store](https://chromium.googlesource.com/chromium/src/+/main/net/data/ssl/chrome_root_store/faq.md).
