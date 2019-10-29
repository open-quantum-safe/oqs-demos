This directory contains instructions and corresponding patches to build the Chromium web browser using the [OQS BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use the quantum-safe key exchange algorithms provided by liboqs.

The fork, and by extension Chromium, at present only support the use of quantum-safe key exchange algorithms in TLS 1.3. Furthermore, the instructions have only been tested on an Ubuntu 19.04 x86_64 machine.

0. Ensure the system requirements listed [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md#System-requirements) are met.

1. To obtain the source code, follow the instructions in the "Install depot_tools" and "Get the code" sections [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md). Be sure to obtain the entire repository history, as we will checkout a specific commit.

2. Navigate to the root directory of the source code, which we will refer to hereafter as `<CHROMIMUM_ROOT>`, and run `git checkout 6d326b9edbf4c2ee1c3ad155d16012acf3c0cc0c`, which is the latest commit for which we have verified the build instructions.

3. Navigate to `<CHROMIUM_ROOT>/third_party/boringssl/src`, and switch the BoringSSL source code to the OQS-BoringSSL fork by running the following commands:

- `git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl`
- `git fetch oqs-bssl`
- `git checkout -b oqs-bssl-master oqs-bssl/master`

4. In a directory of your choosing, clone and build liboqs as follows:

- `git clone --branch master https://github.com/open-quantum-safe/liboqs.git`
- `cd liboqs && autoreconf -i`
- `./configure --prefix=<CHROMIUM_ROOT>/third_party/boringssl/src/oqs --without-openssl --enable-shared=no`
- `make -j && make install`

5. Now, navigate to `<CHROMIUM_ROOT>` and apply the `build.gn.patch` file provided here by running `git apply <PATH_TO_PATCH_FILE>`. Then, navigate to `thid_party/boringssl`, and run `python src/util/generate_build_files.py gn`.

6. Finally, follow the instructions [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md) from the "Install additional build dependencies" section onwards to build and run Chromium.

To verify that Chromium can negotiate a post-quantum key exchange:

1. Navigate again to the `<CHROMIUM_ROOT>/third_party/boringssl/src` folder, and build OQS-BoringSSL as a standalone project by following the instructions in that directory's `README.md` file.
2. Then, in the `build` directory, run `./tool/bssl server -curves oqs_<KEX> -accept localhost:4433", where `<KEX>` is any key-exchange algorithm listed [here](https://github.com/open-quantum-safe/boringssl#supported-algorithms).
3. In the Chromium browser, load `https://localhost:4433`.
