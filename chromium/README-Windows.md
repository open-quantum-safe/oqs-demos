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

* Open _%CHROMIUM_ROOT%/third_party/boringssl/BUILD.gn_.
    * Find `config("external_config")`, then modify `include_dirs`
        ```diff
        config("external_config") {
        -include_dirs = [ "src/include" ]
        +include_dirs = [ "src/include", "src/oqs/include" ]
        if (is_component_build) {
        ```
    * Find `all_headers = crypto_headers + ssl_headers` and replace it with the following line
        ```diff
        all_sources = crypto_sources + ssl_sources
        -all_headers = crypto_headers + ssl_headers
        +all_headers = crypto_headers + ssl_headers + oqs_headers
        
        if (enable_rust_boringssl) {
        ```
    * Find `component("boringssl")`, then add the following line after `friend = [ ":*" ]`
        ```diff
        public = all_headers
        friend = [ ":*" ]
        +libs = [ "//third_party/boringssl/src/oqs/lib/oqs.lib" ]
        deps = [ "//third_party/boringssl/src/third_party/fiat:fiat_license" ]
        ```
* Open _%CHROMIUM_ROOT%/net/quic/quic_stream_factory.cc_.
    * Find `if (quic_stream_factory_->ssl_config_service_->GetSSLContextConfig()`, then modify `config_.set_preferred_groups`
        ```diff
        if (quic_stream_factory_->ssl_config_service_->GetSSLContextConfig()
                .PostQuantumKeyAgreementEnabled()) {
        - config_.set_preferred_groups({SSL_GROUP_X25519_KYBER768_DRAFT00,
        + config_.set_preferred_groups({SSL_GROUP_KYBER512, SSL_GROUP_KYBER768, SSL_GROUP_KYBER1024,
        +                               SSL_GROUP_HQC128, SSL_GROUP_HQC192, SSL_GROUP_HQC256,
        +                               SSL_GROUP_BIKEL1, SSL_GROUP_BIKEL3,
        +                               SSL_GROUP_FRODO640AES, SSL_GROUP_FRODO640SHAKE, SSL_GROUP_FRODO976AES, SSL_GROUP_FRODO976SHAKE, SSL_GROUP_FRODO1344AES, SSL_GROUP_FRODO1344SHAKE,
        +                               SSL_GROUP_X25519_KYBER768_DRAFT00,
        +                               SSL_GROUP_P256_KYBER512, SSL_GROUP_P384_KYBER768, SSL_GROUP_P521_KYBER1024,
        +                               SSL_GROUP_P256_HQC128, SSL_GROUP_P384_HQC192, SSL_GROUP_P521_HQC256,
        +                               SSL_GROUP_P256_BIKEL1, SSL_GROUP_P384_BIKEL3,
        +                               SSL_GROUP_P256_FRODO640AES, SSL_GROUP_P256_FRODO640SHAKE, SSL_GROUP_P384_FRODO976AES, SSL_GROUP_P384_FRODO976SHAKE, SSL_GROUP_P521_FRODO1344AES, SSL_GROUP_P521_FRODO1344SHAKE,
                                        SSL_GROUP_X25519, SSL_GROUP_SECP256R1,
                                        SSL_GROUP_SECP384R1});
        }
        ```
* Open _%CHROMIUM_ROOT%/net/socket/ssl_client_socket_impl.cc_.
    * Find `if (context_->config().PostQuantumKeyAgreementEnabled()) {`, then modify `kCurves`
        ```diff
        if (context_->config().PostQuantumKeyAgreementEnabled()) {
        - static const int kCurves[] = {NID_X25519Kyber768Draft00, NID_X25519,
        -                               NID_X9_62_prime256v1, NID_secp384r1};
        + static const int kCurves[] = {NID_kyber512, NID_kyber768, NID_kyber1024,
        +                               NID_hqc128, NID_hqc192, NID_hqc256,
        +                               NID_bikel1, NID_bikel3,
        +                               NID_p256_kyber512, NID_p384_kyber768, NID_p521_kyber1024,
        +                               NID_p256_hqc128, NID_p384_hqc192, NID_p521_hqc256,
        +                               NID_p256_bikel1, NID_p384_bikel3,
        +                               NID_X25519Kyber768Draft00, NID_frodo640aes, NID_frodo640shake, NID_frodo976aes, NID_frodo976shake, NID_frodo1344aes, NID_frodo1344shake,
        +                               NID_p256_frodo640aes, NID_p256_frodo640shake, NID_p384_frodo976aes, NID_p384_frodo976shake, NID_p521_frodo1344aes, NID_p521_frodo1344shake,
        +                               NID_X25519, NID_X9_62_prime256v1, NID_secp384r1};
          if (!SSL_set1_curves(ssl_.get(), kCurves, std::size(kCurves))) {
            return ERR_UNEXPECTED;
        ```
    * Find `if (ssl_config_.disable_sha1_server_signatures) {`, then insert following lines after `SSL_SIGN_RSA_PSS_RSAE_SHA512,    SSL_SIGN_RSA_PKCS1_SHA512,`
        ```diff
            SSL_SIGN_RSA_PSS_RSAE_SHA384,    SSL_SIGN_RSA_PKCS1_SHA384,
            SSL_SIGN_RSA_PSS_RSAE_SHA512,    SSL_SIGN_RSA_PKCS1_SHA512,
        +   SSL_SIGN_DILITHIUM2, SSL_SIGN_DILITHIUM3, SSL_SIGN_DILITHIUM5,
        +   SSL_SIGN_FALCON512, SSL_SIGN_FALCON1024,
        +   SSL_SIGN_SPHINCSSHA2128FSIMPLE, SSL_SIGN_SPHINCSSHA2128SSIMPLE, SSL_SIGN_SPHINCSSHA2192FSIMPLE, SSL_SIGN_SPHINCSSHA2192SSIMPLE, SSL_SIGN_SPHINCSSHA2256FSIMPLE, SSL_SIGN_SPHINCSSHA2256SSIMPLE,
        +   SSL_SIGN_SPHINCSSHAKE128FSIMPLE, SSL_SIGN_SPHINCSSHAKE128SSIMPLE, SSL_SIGN_SPHINCSSHAKE192FSIMPLE, SSL_SIGN_SPHINCSSHAKE192SSIMPLE, SSL_SIGN_SPHINCSSHAKE256FSIMPLE, SSL_SIGN_SPHINCSSHAKE256SSIMPLE,
        };
        if (!SSL_set_verify_algorithm_prefs(ssl_.get(), kVerifyPrefs,
        ```
* Open _%CHROMIUM_ROOT%/net/cert/cert_verify_proc.cc_.
    * Find `const char* CertTypeToString(X509Certificate::PublicKeyType cert_type) {`, then insert following lines after `return "ECDH";`
        ```diff
          case X509Certificate::kPublicKeyTypeECDH:
            return "ECDH";
        + case X509Certificate::kPublicKeyTypeDilithium:
        +   return "Dilithium";
        + case X509Certificate::kPublicKeyTypeFalcon:
        +   return "Falcon";
        + case X509Certificate::kPublicKeyTypeSPHINCSSHA2:
        +   return "SPHINCSSHA2";
        + case X509Certificate::kPublicKeyTypeSPHINCSSHAKE:
        +   return "SPHINCSSHAKE";
        }
        NOTREACHED();
        ```
    * Find `switch (*cert_algorithm) {`, then insert following lines after `case SignatureAlgorithm::kRsaPssSha512:`
        ```diff
          case SignatureAlgorithm::kRsaPssSha384:
          case SignatureAlgorithm::kRsaPssSha512:
        + case SignatureAlgorithm::kDilithium2:
        + case SignatureAlgorithm::kDilithium3:
        + case SignatureAlgorithm::kDilithium5:
        + case SignatureAlgorithm::kFalcon512:
        + case SignatureAlgorithm::kFalcon1024:
        + case SignatureAlgorithm::kSPHINCSSHA2128fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2128ssimple:
        + case SignatureAlgorithm::kSPHINCSSHA2192fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2192ssimple:
        + case SignatureAlgorithm::kSPHINCSSHA2256fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2256ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE128fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE128ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE192fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE192ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE256fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE256ssimple:
            return true;
        }
        ```
* Open _%CHROMIUM_ROOT%/net/cert/x509_certificate.cc_.
    * Find `switch (EVP_PKEY_id(pkey.get())) {`, then insert following case statements
        ```diff
          case EVP_PKEY_DH:
            *type = kPublicKeyTypeDH;
            break;
        + case EVP_PKEY_DILITHIUM2:
        + case EVP_PKEY_DILITHIUM3:
        + case EVP_PKEY_DILITHIUM5:
        +   *type = kPublicKeyTypeDilithium;
        +   break;
        + case EVP_PKEY_FALCON512:
        + case EVP_PKEY_FALCON1024:
        +   *type = kPublicKeyTypeFalcon;
        +   break;
        + case EVP_PKEY_SPHINCSSHA2128FSIMPLE:
        + case EVP_PKEY_SPHINCSSHA2128SSIMPLE:
        + case EVP_PKEY_SPHINCSSHA2192FSIMPLE:
        + case EVP_PKEY_SPHINCSSHA2192SSIMPLE:
        + case EVP_PKEY_SPHINCSSHA2256FSIMPLE:
        + case EVP_PKEY_SPHINCSSHA2256SSIMPLE:
        +   *type = kPublicKeyTypeSPHINCSSHA2;
        +   break;
        + case EVP_PKEY_SPHINCSSHAKE128FSIMPLE:
        + case EVP_PKEY_SPHINCSSHAKE128SSIMPLE:
        + case EVP_PKEY_SPHINCSSHAKE192FSIMPLE:
        + case EVP_PKEY_SPHINCSSHAKE192SSIMPLE:
        + case EVP_PKEY_SPHINCSSHAKE256FSIMPLE:
        + case EVP_PKEY_SPHINCSSHAKE256SSIMPLE:
        +   *type = kPublicKeyTypeSPHINCSSHAKE;
        +   break;
        }
        *size_bits = base::saturated_cast<size_t>(EVP_PKEY_bits(pkey.get()));
        ```
* Open _%CHROMIUM_ROOT%/net/cert/x509_certificate.h_.
    * Find `enum PublicKeyType {`, then insert following lines before `kPublicKeyTypeECDH`
        ```diff
          kPublicKeyTypeECDSA,
          kPublicKeyTypeDH,
        + kPublicKeyTypeDilithium,
        + kPublicKeyTypeFalcon,
        + kPublicKeyTypeSPHINCSSHA2,
        + kPublicKeyTypeSPHINCSSHAKE,
          kPublicKeyTypeECDH
        };
        ```
* Open _%CHROMIUM_ROOT%/net/cert/pki/signature_algorithm.cc_.
    * Find `[[nodiscard]] bool IsEmpty(const der::Input& input) {`, then insert following lines before it
        ```diff
        const uint8_t kOidMgf1[] = {0x2a, 0x86, 0x48, 0x86, 0xf7,
                                    0x0d, 0x01, 0x01, 0x08};

        +const uint8_t kOidDilithium2[] = {0x2b, 0x06, 0x01, 0x04, 0x01, 0x02, 0x82, 0x0b, 0x07, 0x04, 0x04};
        +const uint8_t kOidDilithium3[] = {0x2b, 0x06, 0x01, 0x04, 0x01, 0x02, 0x82, 0x0b, 0x07, 0x06, 0x05};
        +const uint8_t kOidDilithium5[] = {0x2b, 0x06, 0x01, 0x04, 0x01, 0x02, 0x82, 0x0b, 0x07, 0x08, 0x07};
        +const uint8_t kOidFalcon512[] = {0x2b, 0xce, 0x0f, 0x03, 0x06};
        +const uint8_t kOidFalcon1024[] = {0x2b, 0xce, 0x0f, 0x03, 0x09};
        +const uint8_t kOidSPHINCSSHA2128fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x04, 0x0d};
        +const uint8_t kOidSPHINCSSHA2128ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x04, 0x10};
        +const uint8_t kOidSPHINCSSHA2192fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x05, 0x0a};
        +const uint8_t kOidSPHINCSSHA2192ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x05, 0x0c};
        +const uint8_t kOidSPHINCSSHA2256fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x06, 0x0a};
        +const uint8_t kOidSPHINCSSHA2256ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x06, 0x0c};
        +const uint8_t kOidSPHINCSSHAKE128fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x07, 0x0d};
        +const uint8_t kOidSPHINCSSHAKE128ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x07, 0x10};
        +const uint8_t kOidSPHINCSSHAKE192fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x08, 0x0a};
        +const uint8_t kOidSPHINCSSHAKE192ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x08, 0x0c};
        +const uint8_t kOidSPHINCSSHAKE256fsimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x09, 0x0a};
        +const uint8_t kOidSPHINCSSHAKE256ssimple[] = {0x2b, 0xce, 0x0f, 0x06, 0x09, 0x0c};
        +
        // Returns true if |input| is empty.
        [[nodiscard]] bool IsEmpty(const der::Input& input) {
        ```
    * Find `if (oid == der::Input(kOidRsaSsaPss)) {`, then insert following lines before it
        ```diff
          return SignatureAlgorithm::kEcdsaSha512;
        }

        +if (oid == der::Input(kOidDilithium2)) {
        + return SignatureAlgorithm::kDilithium2;
        +}
        +if (oid == der::Input(kOidDilithium3)) {
        + return SignatureAlgorithm::kDilithium3;
        +}
        +if (oid == der::Input(kOidDilithium5)) {
        + return SignatureAlgorithm::kDilithium5;
        +}
        +if (oid == der::Input(kOidFalcon512)) {
        + return SignatureAlgorithm::kFalcon512;
        +}
        +if (oid == der::Input(kOidFalcon1024)) {
        + return SignatureAlgorithm::kFalcon1024;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2128fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2128fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2128ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2128ssimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2192fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2192fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2192ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2192ssimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2256fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2256fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHA2256ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHA2256ssimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE128fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE128fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE128ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE128ssimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE192fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE192fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE192ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE192ssimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE256fsimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE256fsimple;
        +}
        +if (oid == der::Input(kOidSPHINCSSHAKE256ssimple)) {
        + return SignatureAlgorithm::kSPHINCSSHAKE256ssimple;
        +}
        +
        if (oid == der::Input(kOidRsaSsaPss)) {
          return ParseRsaPss(params);
        ```
    * Find `switch (alg) {`, then add following case statements 
        ```diff
        case SignatureAlgorithm::kRsaPkcs1Sha256:
        case SignatureAlgorithm::kEcdsaSha256:
        +case SignatureAlgorithm::kDilithium2:
        +case SignatureAlgorithm::kFalcon512:
        +case SignatureAlgorithm::kSPHINCSSHA2128fsimple:
        +case SignatureAlgorithm::kSPHINCSSHA2128ssimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE128fsimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE128ssimple:
          return DigestAlgorithm::Sha256;

        case SignatureAlgorithm::kRsaPkcs1Sha384:
        case SignatureAlgorithm::kEcdsaSha384:
        +case SignatureAlgorithm::kDilithium3:
        +case SignatureAlgorithm::kSPHINCSSHA2192fsimple:
        +case SignatureAlgorithm::kSPHINCSSHA2192ssimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE192fsimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE192ssimple:
          return DigestAlgorithm::Sha384;

        case SignatureAlgorithm::kRsaPkcs1Sha512:
        case SignatureAlgorithm::kEcdsaSha512:
        +case SignatureAlgorithm::kDilithium5:
        +case SignatureAlgorithm::kFalcon1024:
        +case SignatureAlgorithm::kSPHINCSSHA2256fsimple:
        +case SignatureAlgorithm::kSPHINCSSHA2256ssimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE256fsimple:
        +case SignatureAlgorithm::kSPHINCSSHAKE256ssimple:
          return DigestAlgorithm::Sha512;

        // It is ambiguous whether hash-matching RSASSA-PSS instantiations count as
        // using one or multiple digests, but the corresponding digest is the only
        ```
* Open _%CHROMIUM_ROOT%/net/cert/pki/signature_algorithm.h_.
    * Find `enum class SignatureAlgorithm {`, then insert following lines after `kRsaPssSha512,`
        ```diff
          kRsaPssSha384,
          kRsaPssSha512,
        + kDilithium2,
        + kDilithium3,
        + kDilithium5,
        + kFalcon512,
        + kFalcon1024,
        + kSPHINCSSHA2128fsimple,
        + kSPHINCSSHA2128ssimple,
        + kSPHINCSSHA2192fsimple,
        + kSPHINCSSHA2192ssimple,
        + kSPHINCSSHA2256fsimple,
        + kSPHINCSSHA2256ssimple,
        + kSPHINCSSHAKE128fsimple,
        + kSPHINCSSHAKE128ssimple,
        + kSPHINCSSHAKE192fsimple,
        + kSPHINCSSHAKE192ssimple,
        + kSPHINCSSHAKE256fsimple,
        + kSPHINCSSHAKE256ssimple,
        };
        ```
* Open _%CHROMIUM_ROOT%/net/cert/pki/simple_path_builder_delegate.cc_.
    * Find `bool IsAcceptableCurveForEcdsa` function, then insert following lines before `switch (curve_nid) {`
        ```diff
        bool IsAcceptableCurveForEcdsa(int curve_nid) {
        +if (IS_OQS_PKEY(curve_nid)) {
        + return true;
        +}
        +
        switch (curve_nid) {
        ```
    * Find `bool SimplePathBuilderDelegate::IsSignatureAlgorithmAcceptable` function, then insert following lines after `case SignatureAlgorithm::kRsaPssSha512:`
        ```diff
          case SignatureAlgorithm::kRsaPssSha384:
          case SignatureAlgorithm::kRsaPssSha512:
        + case SignatureAlgorithm::kDilithium2:
        + case SignatureAlgorithm::kDilithium3:
        + case SignatureAlgorithm::kDilithium5:
        + case SignatureAlgorithm::kFalcon512:
        + case SignatureAlgorithm::kFalcon1024:
        + case SignatureAlgorithm::kSPHINCSSHA2128fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2128ssimple:
        + case SignatureAlgorithm::kSPHINCSSHA2192fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2192ssimple:
        + case SignatureAlgorithm::kSPHINCSSHA2256fsimple:
        + case SignatureAlgorithm::kSPHINCSSHA2256ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE128fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE128ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE192fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE192ssimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE256fsimple:
        + case SignatureAlgorithm::kSPHINCSSHAKE256ssimple:
            return true;
        }
        ```
    * Find `bool SimplePathBuilderDelegate::IsPublicKeyAcceptable` function, then insert following lines before `// Unexpected key type.`
        ```diff
        return true;
        }
        
        +if (IS_OQS_PKEY(pkey_id)) {
        + return true;
        +}
        +
        // Unexpected key type.
        return false;
        ```
* Open _%CHROMIUM_ROOT%/net/cert/pki/verify_signed_data.cc_.
    * Find `bool VerifySignedData` function, then insert following case statements to `switch (algorithm) {`
        ```diff
        std::string_view cache_algorithm_name;
        switch (algorithm) {
        + case SignatureAlgorithm::kDilithium2:
        +   expected_pkey_id = EVP_PKEY_DILITHIUM2;
        +   cache_algorithm_name = "Dilithium2";
        +   break;
        + case SignatureAlgorithm::kDilithium3:
        +   expected_pkey_id = EVP_PKEY_DILITHIUM3;
        +   cache_algorithm_name = "Dilithium3";
        +   break;
        + case SignatureAlgorithm::kDilithium5:
        +   expected_pkey_id = EVP_PKEY_DILITHIUM5;
        +   cache_algorithm_name = "Dilithium5";
        +   break;
        + case SignatureAlgorithm::kFalcon512:
        +   expected_pkey_id = EVP_PKEY_FALCON512;
        +   cache_algorithm_name = "Falcon512";
        +   break;
        + case SignatureAlgorithm::kFalcon1024:
        +   expected_pkey_id = EVP_PKEY_FALCON1024;
        +   cache_algorithm_name = "Falcon1024";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2128fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2128FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2128fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2128ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2128SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2128ssimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2192fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2192FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2192fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2192ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2192SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2192ssimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2256fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2256FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2256fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHA2256ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHA2256SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHA2256ssimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE128fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE128FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE128fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE128ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE128SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE128ssimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE192fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE192FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE192fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE192ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE192SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE192ssimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE256fsimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE256FSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE256fsimple";
        +   break;
        + case SignatureAlgorithm::kSPHINCSSHAKE256ssimple:
        +   expected_pkey_id = EVP_PKEY_SPHINCSSHAKE256SSIMPLE;
        +   cache_algorithm_name = "SPHINCSSHAKE256ssimple";
        +   break;
          case SignatureAlgorithm::kRsaPkcs1Sha1:
            expected_pkey_id = EVP_PKEY_RSA;
        ```
    * Find `crypto::OpenSSLErrStackTracer err_tracer(FROM_HERE);`, then make following changes
        ```diff
          }
        }

        +bool ret;
        +if (IS_OQS_PKEY(expected_pkey_id)) {
        + ret = oqs_verify_sig(public_key, signature_value_bytes.UnsafeData(), signature_value_bytes.Length(), signed_data.UnsafeData(), signed_data.Length()) ? true : false;
        +} else {
        crypto::OpenSSLErrStackTracer err_tracer(FROM_HERE);

        bssl::ScopedEVP_MD_CTX ctx;
        EVP_PKEY_CTX* pctx = nullptr;  // Owned by |ctx|.

        if (!EVP_DigestVerifyInit(ctx.get(), &pctx, digest, nullptr, public_key))
          return false;

        if (is_rsa_pss) {
          // All supported RSASSA-PSS algorithms match signing and MGF-1 digest. They
          // also use the digest length as the salt length, which is specified with -1
          // in OpenSSL's API.
          if (!EVP_PKEY_CTX_set_rsa_padding(pctx, RSA_PKCS1_PSS_PADDING) ||
              !EVP_PKEY_CTX_set_rsa_pss_saltlen(pctx, -1)) {
            return false;
          }
        }

        if (!EVP_DigestVerifyUpdate(ctx.get(), signed_data.UnsafeData(),
                                    signed_data.Length())) {
          return false;
        }

        -bool ret =
        +ret =
            1 == EVP_DigestVerifyFinal(ctx.get(), signature_value_bytes.UnsafeData(),
                                       signature_value_bytes.Length());
        +}

        if (!cache_key.empty()) {
          cache->Store(cache_key, ret ? SignatureVerifyCache::Value::kValid
        ```
* Open _%CHROMIUM_ROOT%/net/base/features.cc_.
    * Find feature `PostQuantumKyber`, then enable it
        ```diff
        BASE_FEATURE(kPostQuantumKyber,
                     "PostQuantumKyber",
        -             base::FEATURE_DISABLED_BY_DEFAULT);
        +             base::FEATURE_ENABLED_BY_DEFAULT);
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

- This guide was initially published on July 1, 2023, and may be outdated.
- A certificate chain that includes quantum-safe signatures can only be validated if it terminates with a root certificate that is in the [Chrome Root Store](https://chromium.googlesource.com/chromium/src/+/main/net/data/ssl/chrome_root_store/faq.md).
- These instructions have been tested on 64-bit Windows 10 Enterprise with Visual Studio 2022 Community, [Go 1.20.5](https://go.dev/dl/), and [ActiveState Perl 5.36](https://www.activestate.com/products/perl/); the Chromium version is 117.0.5863.0.
