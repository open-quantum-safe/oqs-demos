import secrets
import time
from datetime import datetime
from os import symlink
from pathlib import Path

import Crypto
import oqs
import pandas as pd
from Crypto.Hash import SHA512, SHAKE256
from Crypto.PublicKey import ECC, RSA
from Crypto.Signature import DSS, eddsa, pss

MIN_N_SAMPLES = 10
MIN_SAMPLE_TIME_NS = 10**9
SIZE_MESSAGE = 32


def benchmark(func, *args, **kwargs):
    """
    Bencharmks func(*args, **kwargs) calling the function at least MIN_N_SAMPLES. It the function executes very fast,
    more call will be done until MIN_SAMPLE_TIME_NS is reached.
    It retunrs the tuple (average time, number of calls, total time). For convenience later, the average time is
    returned in microseconds (μs), while the total time is returned as nanoseconds (ns) to avoid the precision loss
    caused by the float type.
    """
    times = []
    total_time_ns = 0
    n = 0

    while n < MIN_N_SAMPLES or total_time_ns < MIN_SAMPLE_TIME_NS:
        start = time.perf_counter_ns()
        func(*args, **kwargs)
        end = time.perf_counter_ns()
        times.append(end - start)
        total_time_ns += end - start
        n += 1

    avg_time_us = sum(times) / n / 1e3
    return avg_time_us, n, total_time_ns


def benchmark_traditional_sigs(debug=False):
    """
    Here, a selection of classical digital signature algorithms are bencharmed.
    """
    nist_sec_level = [1, 1, 1, 1, 3, 5, 1, 5]
    public_key_lengths = []
    secret_key_lenghts = []
    signature_lenghts = []
    # Measured times in μs
    keygen_times = []
    sign_times = []
    verify_times = []
    sig_algs = [
        "RSASSA-PSS (2048)",
        "RSASSA-PSS (3072)",
        "RSASSA-PSS (4096)",
        "P-256",
        "P-384",
        "P-521",
        "Ed25519",
        "Ed448",
    ]
    _sig_algs = [RSA, ECC]
    _rsa_bits = [2048, 3072, 4096]
    _ecdsa = [
        "p256",
        "p384",
        "p521",
    ]
    _eddsa = [
        "ed25519",
        "ed448",
    ]
    n_sig_algs = len(_rsa_bits) + len(_ecdsa) + len(_eddsa)

    print("Benchmarking traditional sig algs (RSA, ECC)")

    i = 0
    for alg in _sig_algs:
        if alg == RSA:
            for bits in _rsa_bits:
                print(f"RSASSA-PSS ({bits}) {i + 1}/{n_sig_algs}", end="", flush=True)
                secret_key_lenghts.append(len(alg.generate(bits).export_key(format="DER")))
                public_key_lengths.append(len(alg.generate(bits).public_key().export_key(format="DER")))

                # Measure keygen
                avg, n, total = benchmark(alg.generate, bits)
                if debug:
                    print(f"\nCalls to generate({bits}): {n}")
                    print(f"Total time: {total}")
                keygen_times.append(avg)
                print(".", end="", flush=True)

                # Measure sign
                privkey = alg.generate(bits)
                signer = pss.new(privkey)
                message = secrets.token_bytes(SIZE_MESSAGE)
                h = SHA512.new(message)
                signature_lenghts.append(len(signer.sign(h)))

                avg, n, total = benchmark(signer.sign, h)
                if debug:
                    print(f"\nCalls to sign(h): {n}")
                    print(f"Total time: {total}")
                sign_times.append(avg)
                print(".", end="", flush=True)

                # Measure verify
                message = secrets.token_bytes(SIZE_MESSAGE)
                h = SHA512.new(message)
                signature = signer.sign(h)
                pubkey = privkey.public_key()
                verifier = pss.new(pubkey)

                avg, n, total = benchmark(verifier.verify, h, signature)
                if debug:
                    print(f"\nCalls to verify(h, signature): {n}")
                    print(f"Total time: {total}")
                verify_times.append(avg)
                print(".✓")
                i += 1

        elif alg == ECC:
            for curve in _ecdsa:
                print(f"ECDSA ({curve}) {i + 1}/{n_sig_algs}", end="", flush=True)
                secret_key_lenghts.append(len(alg.generate(curve=curve).export_key(format="DER")))
                public_key_lengths.append(len(alg.generate(curve=curve).public_key().export_key(format="DER")))

                # Measure keygen
                avg, n, total = benchmark(alg.generate, curve=curve)
                if debug:
                    print(f"\nCalls to generate(curve={curve})): {n}")
                    print(f"Total time: {total}")
                keygen_times.append(avg)
                print(".", end="", flush=True)

                # Measure sign
                privkey = alg.generate(curve=curve)
                signer = DSS.new(privkey, mode="fips-186-3")
                message = secrets.token_bytes(SIZE_MESSAGE)
                h = SHA512.new(message)
                signature_lenghts.append(len(signer.sign(h)))

                avg, n, total = benchmark(signer.sign, h)
                if debug:
                    print(f"\nCalls to sign(h): {n}")
                    print(f"Total time: {total}")
                sign_times.append(avg)
                print(".", end="", flush=True)

                # Measure verify
                message = secrets.token_bytes(SIZE_MESSAGE)
                h = SHA512.new(message)
                signature = signer.sign(h)
                pubkey = privkey.public_key()
                verifier = DSS.new(pubkey, mode="fips-186-3")

                avg, n, total = benchmark(verifier.verify, h, signature)
                if debug:
                    print(f"\nCalls to verify(h, signature): {n}")
                    print(f"Total time: {total}")
                verify_times.append(avg)
                print(".✓")
                i += 1

            print("EdDSA", end="", flush=True)
            for curve in _eddsa:
                print(f"EdDSA ({curve}) {i + 1}/{n_sig_algs}", end="", flush=True)
                secret_key_lenghts.append(len(alg.generate(curve=curve).export_key(format="DER")))
                public_key_lengths.append(len(alg.generate(curve=curve).public_key().export_key(format="DER")))

                # Measure keygen
                avg, n, total = benchmark(alg.generate, curve=curve)
                if debug:
                    print(f"\nCalls to generate(curve={curve}): {n}")
                    print(f"Total time: {total}")
                keygen_times.append(avg)
                print(".", end="", flush=True)

                # Measure sign
                privkey = alg.generate(curve=curve)
                signer = eddsa.new(privkey, mode="rfc8032")
                message = secrets.token_bytes(SIZE_MESSAGE)
                if curve == "ed25519":
                    h = SHA512.new(message)
                elif curve == "ed448":
                    h = SHAKE256.new(message)
                else:
                    raise RuntimeError
                signature_lenghts.append(len(signer.sign(h)))

                avg, n, total = benchmark(signer.sign, h)
                if debug:
                    print(f"\nCalls to sign(h): {n}")
                    print(f"Total time: {total}")
                sign_times.append(avg)
                print(".", end="", flush=True)

                # Measure verify
                message = secrets.token_bytes(SIZE_MESSAGE)
                if curve == "ed25519":
                    h = SHA512.new(message)
                elif curve == "ed448":
                    h = SHAKE256.new(message)
                else:
                    raise RuntimeError
                signature = signer.sign(h)
                pubkey = privkey.public_key()
                verifier = eddsa.new(pubkey, mode="rfc8032")

                avg, n, total = benchmark(verifier.verify, h, signature)
                if debug:
                    print(f"\nCalls to verify(h, signature): {n}")
                    print(f"Total time: {total}")
                verify_times.append(avg)
                print(".✓")
                i += 1

    print("Saving dataframe", end="")
    df = pd.DataFrame(
        data={
            "Algorithm": sig_algs,
            "NIST": nist_sec_level,
            "Pubkey (bytes)": public_key_lengths,
            "Privkey (bytes)": secret_key_lenghts,
            "Signature (bytes)": signature_lenghts,
            "Keygen (μs)": keygen_times,
            "Sign (μs)": sign_times,
            "Verify (μs)": verify_times,
        }
    )
    df.set_index("Algorithm", inplace=True)
    df.sort_index(inplace=True)
    print(" ✓")
    return df


def benchmark_pqc_sigs(debug=False):
    """
    Here, available PQC digital signature algorithms in liboqs are bencharmed.
    """
    nist_sec_level = []
    public_key_lengths = []
    secret_key_lenghts = []
    signature_lenghts = []
    # Measured times in μs
    keygen_times = []
    sign_times = []
    verify_times = []

    sig_algs = oqs.get_supported_sig_mechanisms()
    n_sig_algs = len(sig_algs)

    print("Benchmarking PQC sig algs")
    for n, alg_name in enumerate(sig_algs):
        print(f"{alg_name} {n + 1}/{n_sig_algs}", end="")
        with oqs.Signature(alg_name) as signer:
            with oqs.Signature(alg_name) as verifier:
                nist_sec_level.append(signer.claimed_nist_level)
                public_key_lengths.append(signer.length_public_key)
                secret_key_lenghts.append(signer.length_secret_key)
                signature_lenghts.append(signer.length_signature)

                # Measure keygen
                avg, n, total = benchmark(signer.generate_keypair)
                if debug:
                    print(f"\nCalls to generate_keypair(): {n}")
                    print(f"Total time: {total}")
                keygen_times.append(avg)
                print(".", end="")

                # Measure sign
                pubkey = signer.generate_keypair()
                message = secrets.token_bytes(SIZE_MESSAGE)
                avg, n, total = benchmark(signer.sign, message)
                if debug:
                    print(f"\nCalls to sign(message): {n}")
                    print(f"Total time: {total}")
                sign_times.append(avg)
                print(".", end="")

                # Measure verify
                signature = signer.sign(message)
                avg, n, total = benchmark(verifier.verify, message, signature, pubkey)
                if debug:
                    print(f"\nCalls to verify(message, signature, pubkey): {n}")
                    print(f"Total time: {total}")
                verify_times.append(avg)
                print(".✓")

    print("\nSaving dataframe", end="")
    df = pd.DataFrame(
        data={
            "Algorithm": oqs.get_supported_sig_mechanisms(),
            "NIST": nist_sec_level,
            "Pubkey (bytes)": public_key_lengths,
            "Privkey (bytes)": secret_key_lenghts,
            "Signature (bytes)": signature_lenghts,
            "Keygen (μs)": keygen_times,
            "Sign (μs)": sign_times,
            "Verify (μs)": verify_times,
        }
    )
    df.set_index("Algorithm", inplace=True)
    df.sort_index(inplace=True)
    print(" ✓")
    return df


def main():
    debug = False
    t0 = time.perf_counter()
    print(f"MIN_N_SAMPLES = {MIN_N_SAMPLES}")
    print(f"MIN_SAMPLE_TIME_NS = {MIN_SAMPLE_TIME_NS}")
    print(f"SIZE_MESSAGE = {SIZE_MESSAGE}\n")
    df_traditional = benchmark_traditional_sigs(debug)
    print()
    df_pqc = benchmark_pqc_sigs(debug)
    df = pd.concat([df_traditional, df_pqc]).sort_index()
    t1 = time.perf_counter() - t0
    ts = datetime.now().isoformat()
    df.attrs = {
        "timestamp": ts,
        "duration": t1,
        "MIN_N_SAMPLES": MIN_N_SAMPLES,
        "MIN_SAMPLE_TIME_NS": MIN_SAMPLE_TIME_NS,
        "SIZE_MESSAGE": SIZE_MESSAGE,
        "liboqs_version": oqs.oqs_python_version(),
        "pycryptodome_version": Crypto.__version__,
    }
    filename = f"{ts}.zst"
    dir = Path(__file__).resolve().parent / "webapp" / "data"
    df.to_pickle(dir / filename, compression="zstd")
    print(f"\nDataFrame generated in {t1 // 60:.0f}m {t1 % 60:.0f}s")
    latest_symlink = dir / "latest.zst"
    if latest_symlink.exists():
        latest_symlink.unlink()
    symlink(filename, dir / "latest.zst")


if __name__ == "__main__":
    main()
