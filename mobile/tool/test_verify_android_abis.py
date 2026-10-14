import tempfile
import unittest
import zipfile
import struct
from pathlib import Path
from verify_android_abis import EXPECTED, verify


class AbiVerificationTest(unittest.TestCase):
    def bundle(self, path, *, missing=False, wrong=False):
        with zipfile.ZipFile(path, 'w') as output:
            for abi, (elf_class, machine) in EXPECTED.items():
                for library in ('libapp.so', 'libflutter.so', 'libdartjni.so'):
                    if missing and abi == 'x86_64' and library == 'libflutter.so':
                        continue
                    header = bytearray(20)
                    header[:4] = b'\x7fELF'
                    header[4:6] = bytes((elf_class, 1))
                    struct.pack_into('<H', header, 18, 183 if wrong and abi == 'x86_64' else machine)
                    output.writestr(f'base/lib/{abi}/{library}', header)

    def test_complete_and_invalid_payloads(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fixture.aab'
            self.bundle(path)
            self.assertEqual(verify(path), 9)
            self.bundle(path, missing=True)
            with self.assertRaisesRegex(AssertionError, 'Missing'):
                verify(path)
            self.bundle(path, wrong=True)
            with self.assertRaisesRegex(AssertionError, 'Wrong architecture'):
                verify(path)


if __name__ == '__main__':
    unittest.main()
