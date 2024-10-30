# Instructions for Building Chromium on Windows

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/windows_build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **%CHROMIUM_ROOT%** to refer to the root directory of the Chromium source code.\
You may set `CHROMIUM_ROOT` variable by running `set CHROMIUM_ROOT=/path/to/the/Chromium/source` in Command Prompt.

In Command Prompt, run following commands:

```bat
cd %CHROMIUM_ROOT%
git checkout tags/131.0.6769.0
gclient sync
```

### 2. Switch to the OQS-BoringSSL

In Command Prompt, run following commands:

```bat
cd %CHROMIUM_ROOT%/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master 0599bb559d3be76a98f0940d494411b6a8e0b18e
```

### 3. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use msbuild instead of ninja to build liboqs.\
Start _x64 Native Tools Command Prompt for VS 2022_ (usually it's in _C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2022\Visual Studio Tools\VC_) and run following commands:

```bat
git clone https://github.com/open-quantum-safe/liboqs.git && cd liboqs && git checkout 9aa2e1481cd0c242658ec8e92776741feabec163
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=%CHROMIUM_ROOT%/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF -DCMAKE_BUILD_TYPE=Release
msbuild ALL_BUILD.vcxproj
msbuild INSTALL.vcxproj
```

### 4. Enable Quantum-Safe Crypto

Download the [oqs-Windows.patch](https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-Windows.patch) and save it at _%CHROMIUM_ROOT%_, then apply the patch by running

```bat
git apply oqs-Windows.patch
```

### 5. Build

In Command Prompt, run following commands:

```bat
cd %CHROMIUM_ROOT%
gn args out/Default
```

Then append following lines to the configuration file opened in editor:

```
is_debug = false
symbol_level = 0
enable_nacl = false
blink_symbol_level = 0
target_cpu = "x64"
target_os = "win"
```

Save and close the configuration file. Last, run `autoninja -C out/Default chrome` in Command Prompt.\
If the build completes successfully, it will create _chrome.exe_ in _%CHROMIUM_ROOT%/out/Default_.

### 6. Miscellaneous

- BIKE key exchange is not supported.
- This guide was initially published on October 10, 2024, and may be outdated.
