This directory contains instructions and corresponding patches to build the Chromium web browser using the [OQS-BoringSSL fork](https://github.com/open-quantum-safe/boringssl), thereby enabling Chromium to use quantum-safe key exchange algorithms. Note that these instructions have only been tested on an Ubuntu 19.10 x86_64 machine and apply at present only to a subset of quantum-safe key-exchanges as [documented here](https://github.com/open-quantum-safe/boringssl#key-exchange).

Further be aware that both cloning the source code as well as building Chromium can take several hours if you do not have excellent network connectivity and serious multicore CPUs at your disposal.

0. Ensure the system requirements listed [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#System-requirements) are met.

1. To obtain the source code, follow the instructions in the "Install depot_tools" and "Get the code" sections [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#Install). Note: Do *not* set `--no-history` to save time as you need git history in the next step.

2. Navigate to the root directory of the source code, which we will refer to hereafter as `<CHROMIMUM_ROOT>`, and run `git checkout 85.0.4161.2`, which is the latest tag for which we have verified the build instructions. Then, to ensure that all of chromium's third party dependencies are compatible with this tag, run `gclient sync`.

3. Navigate to `<CHROMIUM_ROOT>/third_party/boringssl/src`, and switch the BoringSSL source code to the OQS-BoringSSL fork by running the following commands:

- `git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl`
- `git fetch oqs-bssl`
- `git checkout -b oqs-bssl-master oqs-bssl/master`

4. In a directory of your choosing, clone and build liboqs as follows:

- `git clone --branch master https://github.com/open-quantum-safe/liboqs.git`
- `cd liboqs && mkdir build && cd build`
- `cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=<CHROMIUM_ROOT>/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF`
- `ninja && ninja install`

Note: You might have to install `ninja` if not already done, e.g., by running `sudo apt-get install ninja`. You also might want to run `SKIP_TESTS=doxygen,style ninja run_tests` to validate liboqs operating OK on your machine. For this you need to install `pytest` if not already present on your machine, e.g., by running `sudo apt-get install python3-pytest python3-pytest-xdist` first.

5. After successfully installing liboqs as per the above, navigate to `<CHROMIUM_ROOT>` and apply the `BUILD.gn.patch` file provided here by running `git apply <PATH_TO_PATCH_FILE>`. Then, navigate to `third_party/boringssl`, and run `python src/util/generate_build_files.py gn`.

Note: For this to succeed, you might have to install go if not already present on your machine, e.g., by running `sudo apt install golang-go`.

6. Finally, navigate back to <CHROMIUM_ROOT> and follow the instructions [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#Install-additional-build-dependencies) from the "Install additional build dependencies" section onwards to build Chromium.

To verify that Chromium can perform a TLS 1.3 handshake using a post-quantum key exchange:

0. Navigate to `<CHROMIUM_ROOT>`, and start Chromium by executing `./out/Default/chrome`
1. Navigate again to the `<CHROMIUM_ROOT>/third_party/boringssl/src` folder, and build OQS-BoringSSL as a standalone project by running `mkdir build && cd build && cmake -GNinja ..`.
2. Then, in the `build` directory, run `./tool/bssl server -accept 4433 -www -loop -curves <KEX>`, where `<KEX>` can be any key-exchange algorithm named [here](https://github.com/open-quantum-safe/boringssl#supported-algorithms) that is supported by default by Chromium. The [kDefaultGroups array](https://github.com/open-quantum-safe/boringssl/blob/master/ssl/t1_lib.cc#L375) lists all such algorithms\*.
3. Load `https://localhost:4433` in Chromium.

An alternative test consists of using the newly built Chromium to access the OQS test server at [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and clicking on any of the algorithm combinations [supported by Chromium](https://github.com/open-quantum-safe/boringssl/blob/master/ssl/t1_lib.cc#L375), e.g., `p256_kyber512` (running at [port 6071](https://test.openquantumsafe.org:6071) ).

\* For an explanation of why Chromium supports only a subset of key-exchange algorithms by default, consult [OQS-BoringSSL's Implementation Notes wiki page](https://github.com/open-quantum-safe/boringssl/wiki/Implementation-Notes).
