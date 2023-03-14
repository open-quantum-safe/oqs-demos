These instructions have been tested only on Ubuntu 18, 19, and 20 (x86_64) installations and apply at present only to a subset of quantum-safe key-exchanges as [documented here](https://github.com/open-quantum-safe/boringssl#key-exchange).

0. Ensure the system requirements listed [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#System-requirements) are met.

1. To obtain the source code, follow the instructions in the "Install depot_tools" and "Get the code" sections [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#Install). Note: Do *not* set `--no-history` to save time as you need git history in the next step.

2. Navigate to the root directory of the source code, which we will refer to hereafter as `<CHROMIMUM_ROOT>`, and run `git checkout 100.0.4856.2`, which is the latest tag for which we have verified the build instructions. Then, to ensure that all of chromium's third party dependencies are compatible with this tag, run `gclient sync`.

*Note*: Depending on the OS version installed, you may have to install python2, e.g., using `sudo apt install -y python2`, and ensure it's set as the system default, e.g., via `sudo ln -s /usr/bin/python2 /usr/bin/python`.

3. Navigate to `<CHROMIUM_ROOT>/third_party/boringssl/src`, and switch the BoringSSL source code to the OQS-BoringSSL fork by running the following commands:

- `git remote add oqs-bssl https://github.com/open-quantum-safe/boringssl`
- `git fetch oqs-bssl`
- `git checkout -b oqs-bssl-master oqs-bssl/master`

4. In a directory of your choosing, clone and build liboqs as follows:

- `git clone --branch main https://github.com/open-quantum-safe/liboqs.git`
- `cd liboqs && mkdir build && cd build`
- `cmake .. -G"Ninja" -DCMAKE_INSTALL_PREFIX=<CHROMIUM_ROOT>/third_party/boringssl/src/oqs -DOQS_USE_OPENSSL=OFF`
- `ninja && ninja install`

Note: You might have to install `ninja` if not already done, e.g., by running `sudo apt-get install ninja`. You also might want to run `SKIP_TESTS=doxygen,style ninja run_tests` to validate liboqs operating OK on your machine. For this you need to install `pytest` if not already present on your machine, e.g., by running `sudo apt-get install python3-pytest python3-pytest-xdist` first.

Note: If you want to execute the resulting binaries on another machine, be sure to also pass [-DOQS_DIST_BUILD=ON](https://github.com/open-quantum-safe/liboqs/wiki/Customizing-liboqs#oqs_dist_build) to the `cmake` command above to obtain code running on all machines of the same architecture type.

5. After successfully installing liboqs as per the above, navigate to `<CHROMIUM_ROOT>` and apply the `oqs-changes.patch` file provided here by running `git apply <PATH_TO_PATCH_FILE>`. Then, navigate to `third_party/boringssl`, and run `python src/util/generate_build_files.py gn`.

Note: For this to succeed, you might have to install go if not already present on your machine, e.g., by running `sudo apt install golang-go`. If _any_ error occurs in this step, Chromium will build fine, just without support for quantum-safe crypto, i.e., only the final testing steps below will fail.

6. Finally, navigate back to <CHROMIUM_ROOT> and follow the instructions [here](https://chromium.googlesource.com/chromium/src/+/master/docs/linux/build_instructions.md#Install-additional-build-dependencies) from the "Install additional build dependencies" section onwards to build Chromium. 

Note: If you have already built another chromium source tree (version), you may have to execute `gclient sync --force` to ensure all dependencies are properly updated.

Note: It is *strongly* advisable to set certain build options to obtain a size-and-performance optimized chromium variant, also saving on build time. Do this by executing `gn args out/Default` and adding the following variables to the configuration file opened in your editor:
```
# Set build arguments here. See `gn help buildargs`.
is_debug = false
symbol_level = 0
enable_nacl = false
blink_symbol_level=0
```


If the build completes successfully, i.e., the executable `chrome` has been created, one can verify that Chromium can perform a TLS 1.3 handshake using a post-quantum key exchange by executing these steps:

0. Navigate to `<CHROMIUM_ROOT>`, and start Chromium by executing `./out/Default/chrome`
1. Navigate again to the `<CHROMIUM_ROOT>/third_party/boringssl/src` folder, and build OQS-BoringSSL as a standalone project by running `mkdir build && cd build && cmake -GNinja ..`.
2. Then, in the `build` directory, run `./tool/bssl server -accept 4433 -www -loop -curves <KEX>`, where `<KEX>` can be any key-exchange algorithm named [here](https://github.com/open-quantum-safe/boringssl#supported-algorithms) that is supported by default by Chromium. The [kDefaultGroups array](https://github.com/open-quantum-safe/boringssl/wiki/Implementation-Notes) lists all such algorithms\*.
3. Load `https://localhost:4433` in Chromium.

An alternative test consists of using the newly built Chromium to access the OQS test server at [https://test.openquantumsafe.org](https://test.openquantumsafe.org) and clicking on any of the algorithm combinations [supported by Chromium](https://github.com/open-quantum-safe/boringssl/blob/master/ssl/t1_lib.cc#L375), e.g., `p256_kyber90s512`).

Note: In order to avoid certificate warnings, you need to [download the test site certificate](https://test.openquantumsafe.org/CA.crt) using the newly-built chromium. Then click the "..." Control extensions button in the top-right window corner of your newly built Chromium browser, select "Settings", click on "Privacy and Security" in the newly opened window on the left, click on "Security" in the window pane on the right, scroll down and click on "Manage certificates", click on the "Certificates" tab in the newly opened screen, click on "Import" near the top of the newly opened pane and click on the "Downloads" folder on the file selector window that opens. Then double-click on "CA.crt" and check the box next to "Trust this certificate for identifying websites" and finally click "OK".

*Note: If you already had been running an OQS-enabled chromium and upgraded to a more current version, clearing the cache is strongly advised to avoid "inexplicable" errors.*

\* For an explanation of why Chromium supports only a subset of key-exchange algorithms by default, consult [OQS-BoringSSL's Implementation Notes wiki page](https://github.com/open-quantum-safe/boringssl/wiki/Implementation-Notes).

### Shipping binary

If all steps outlined above have been successfully executed, one can extract a standalone binary distribution by running `tar czvf chromium-binary.tgz *` within the directory `<CHROMIUM_ROOT>/out/Default` and moving the resulting `tgz` archive to a suitable machine with all UI components for execution. In order to not transfer too many unnecessary files, passing the options `--exclude='obj/*' --exclude='gen/*' --exclude=v8_context_snapshot_generator --exclude=mksnapshot --exclude=make_top_domain_list_variables --exclude=toolchain.ninja --exclude='*__pycache__*' ` to the `tar` command eliminates many files that are not essential for correct operation of a binary Chromium (v94) release.

### Automated build scripts
As the instructions above are complex and hard to get right the first time, a set of build scripts is included in the 
scripts subdirectory. Please read scripts/README for more information on how to use them.

