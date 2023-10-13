# Instructions for Building Chromium on Windows

### 1. Obtain the Chromium Source Code

Please read [Google's instructions](https://chromium.googlesource.com/chromium/src/+/HEAD/docs/windows_build_instructions.md) carefully, then complete every step before **Setting up the build**.

The rest of the instructions will use **%CHROMIUM_ROOT%** to refer to the root directory of the Chromium source code.\
You may set `CHROMIUM_ROOT` variable by running `set CHROMIUM_ROOT=/path/to/the/Chromium/source` in Command Prompt.

### 2. Install Go and Perl

### 3. Switch to the OQS-BoringSSL

In Command Prompt, run following commands:

```bat
cd %CHROMIUM_ROOT%/third_party/boringssl/src
git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl
git fetch oqs-bssl
git checkout -b oqs-bssl-master 1ca41b49e9198f510991fb4f350b4a5fd4c1d5ff
```

### 4. Clone and Build liboqs

Choose a directory to store the liboqs source code and use the `cd` command to move to that directory. We will use msbuild instead of ninja to build liboqs.\
Start _x64 Native Tools Command Prompt for VS 2022_ (usually it's in _C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio 2022\Visual Studio Tools\VC_) and run following commands:

```bat
git clone --branch main https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=%CHROMIUM_ROOT%/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF
msbuild ALL_BUILD.vcxproj
msbuild INSTALL.vcxproj
```

### 5. Enable Quantum-Safe Crypto

Download the [oqs-changes.patch](https://raw.githubusercontent.com/open-quantum-safe/oqs-demos/main/chromium/oqs-changes.patch) and save it at _%CHROMIUM_ROOT%_, then apply the patch by running

```bat
git apply oqs-changes.patch
```

Open _%CHROMIUM_ROOT%/third_party/boringssl/BUILD.gn_ and find `libs = [ "//third_party/boringssl/src/oqs/lib/liboqs.a" ]`, then replace it with

```diff
public = all_headers
friend = [ ":*" ]
-libs = [ "//third_party/boringssl/src/oqs/lib/liboqs.a" ]
+libs = [ "//third_party/boringssl/src/oqs/lib/oqs.lib" ]
deps = [ "//third_party/boringssl/src/third_party/fiat:fiat_license" ]
```

### 6. Generate BoringSSL Build Files for Chromium

In Command Prompt, run following commands:

```bat
cd %CHROMIUM_ROOT%/third_party/boringssl
python src/util/generate_build_files.py gn
```

### 7. Build

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

### 8. Miscellaneous

- BIKE key exchange will crash Chromium.
- This guide was initially published on July 1, 2023, and may be outdated.
- A certificate chain that includes quantum-safe signatures can only be validated if it terminates with a root certificate that is in the [Chrome Root Store](https://chromium.googlesource.com/chromium/src/+/main/net/data/ssl/chrome_root_store/faq.md).
- These instructions have been tested on 64-bit Windows 10 Enterprise with Visual Studio 2022 Community, [Go 1.20.5](https://go.dev/dl/), and [ActiveState Perl 5.36](https://www.activestate.com/products/perl/).
