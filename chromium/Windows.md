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
git checkout -b oqs-bssl-master oqs-bssl/master
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

* Open _%CHROMIUM_ROOT%/net/cert/pki/simple_path_builder_delegate.cc_.
    * Find `bool IsAcceptableCurveForEcdsa` function, then insert following lines before `switch (curve_nid) {`
        ```diff
        bool IsAcceptableCurveForEcdsa(int curve_nid) {
        +if (IS_OQS_PKEY(curve_nid)) {
        +  return true;
        +}
        +
        switch (curve_nid) {
        ```
    * Find `bool SimplePathBuilderDelegate::IsPublicKeyAcceptable` function, then insert following lines before `// Unexpected key type.`:
        ```diff
        return true;
        }
        
        +if (IS_OQS_PKEY(pkey_id)) {
        +  return true;
        +}
        +
        // Unexpected key type.
        return false;
        ```
* Open _%CHROMIUM_ROOT%/third_party/boringssl/BUILD.gn_.
    * Find `config("external_config")`, then modify `include_dirs`:
        ```diff
        config("external_config") {
        -include_dirs = [ "src/include" ]
        +include_dirs = [ "src/include", "src/oqs/include" ]
        if (is_component_build) {
        ```
    * Find `all_headers = crypto_headers + ssl_headers` and replace it with the following line:
        ```diff
        all_sources = crypto_sources + ssl_sources
        -all_headers = crypto_headers + ssl_headers
        +all_headers = crypto_headers + ssl_headers + oqs_headers
        
        # Windows' assembly is built with NASM. The other platforms use the platform
        ```
    * Find `component("boringssl")`, then add the following line after `friend = [ ":*" ]`:
        ```diff
        public = all_headers
        friend = [ ":*" ]
        +libs = [ "//third_party/boringssl/src/oqs/lib/oqs.lib" ]
        deps = [ "//third_party/boringssl/src/third_party/fiat:fiat_license" ]
        ```
* Open _%CHROMIUM_ROOT%/third_party/boringssl/src/util/generate_build_files.py_.
    * Replace `if arch in ArchForAsmFilename(filename):` with the following line:
        ```diff
        output = output.replace('${ASM_EXT}', asm_ext)
        
        -if arch in ArchForAsmFilename(filename):
        +if arch in ArchForAsmFilename(filename) and "x" in arch:
          PerlAsm(output, perlasm['input'], perlasm_style,
                  perlasm['extra_args'] + extra_args)
        ```

### 6. Generate BoringSSL Build Files for Chromium

In _x64 Native Tools Command Prompt for VS 2022_, run following commands:

```bat
cd %CHROMIUM_ROOT%/third_party/boringssl
python src/util/generate_build_files.py gn
```

### 7. Update Chromium Source Code

In _%CHROMIUM_ROOT%/net/socket/ssl_client_socket_impl.cc_, `static const int kCurves[]` array contains `NID_X25519Kyber768` and `NID_P256Kyber768`, which are not defined in _nid.h_ of OQS-BoringSSL, so we need to remove them.\
Find `if (base::FeatureList::IsEnabled(features::kPostQuantumKyber))`, then modify `static const int kCurves[]` array:

```diff
if (base::FeatureList::IsEnabled(features::kPostQuantumKyber)) {
-  static const int kCurves[] = {NID_X25519Kyber768, NID_X25519,
-                                NID_P256Kyber768, NID_X9_62_prime256v1,
+  static const int kCurves[] = {NID_X25519, NID_X9_62_prime256v1,
                                NID_secp384r1};
  if (!SSL_set1_curves(ssl_.get(), kCurves, std::size(kCurves))) {
    return ERR_UNEXPECTED;
```

### 8. Build

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

### 9. Miscellaneous

- This guide was initially published on March 12, 2023, and may be outdated.
- These instructions have been tested on 64-bit Windows 10 Enterprise with Visual Studio 2022 Community, [Go 1.20.2](https://go.dev/dl/), and [ActiveState Perl 5.36](https://www.activestate.com/products/perl/); the Chromium version is 113.0.5649.0.
- A prebuilt 64-bit Chromium installer (based on Chromium 113.0.5649.0) is available [here](https://ipfs.io/ipfs/bafkreibrv24koqv3e7feyndxt3nflxvmvqw7yok4mmd3d5bqsay625cdfa).