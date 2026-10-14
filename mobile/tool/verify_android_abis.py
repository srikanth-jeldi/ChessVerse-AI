"""Reject incomplete or mislabeled native ABI payloads before Play upload."""
import struct
import sys
import zipfile

EXPECTED = {"armeabi-v7a": (1, 40), "arm64-v8a": (2, 183), "x86_64": (2, 62)}


def verify(path):
    with zipfile.ZipFile(path) as bundle:
        names = set(bundle.namelist())
        for abi in EXPECTED:
            for library in ("libapp.so", "libflutter.so", "libdartjni.so"):
                assert f"base/lib/{abi}/{library}" in names, f"Missing {abi}/{library}"
        count = 0
        for name in sorted(names):
            if not name.startswith("base/lib/") or not name.endswith(".so"):
                continue
            abi = name.split("/")[2]
            assert abi in EXPECTED, f"Unexpected ABI: {abi}"
            with bundle.open(name) as source:
                header = source.read(20)
            assert header[:4] == b"\x7fELF" and len(header) == 20, f"Invalid ELF: {name}"
            assert header[5] == 1, f"Unexpected byte order: {name}"
            actual = (header[4], struct.unpack_from("<H", header, 18)[0])
            assert actual == EXPECTED[abi], f"Wrong architecture: {name}: {actual}"
            count += 1
    return count


if __name__ == "__main__":
    print(f"Verified {verify(sys.argv[1])} native libraries across all 3 ABIs")
