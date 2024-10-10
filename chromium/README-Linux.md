# Instructions for Building Chromium on Linux

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/main/docs/linux/build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **$CHROMIUM_ROOT** to refer to the root directory of the Chromium source code.

```shellscript
cd $CHROMIUM_ROOT
git checkout tags/131.0.6767.0
gclient sync
```

### 2. Switch to the OQS-BoringSSL

```shellscript
cd $CHROMIUM_ROOT/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master 0599bb559d3be76a98f0940d494411b6a8e0b18e
```

### 3. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use ninja to build liboqs.

```shellscript
git clone https://github.com/open-quantum-safe/liboqs.git && git checkout 9aa2e1481cd0c242658ec8e92776741feabec163
cd liboqs && mkdir build && cd build
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

- This guide is published on October 10, 2024, and may be outdated.
