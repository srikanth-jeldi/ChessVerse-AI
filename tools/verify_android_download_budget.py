"""Check bundle completeness and bundletool's compressed download estimates."""
import argparse
import csv
import json
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--bundle', type=Path, required=True)
parser.add_argument('--baseline', type=Path, required=True)
parser.add_argument('--size-csv', type=Path, required=True)
parser.add_argument('--max-bytes', type=int, default=25_000_000)
args = parser.parse_args()

with zipfile.ZipFile(args.baseline) as old, zipfile.ZipFile(args.bundle) as new:
    old_names, new_names = set(old.namelist()), set(new.namelist())
    protected = {n for n in old_names if n.startswith(('base/assets/', 'base/lib/'))}
    missing = protected - new_names
    assert not missing, f'Missing assets/native files: {sorted(missing)}'
    libs = sorted(n for n in new_names if n.startswith('base/lib/') and n.endswith('.so'))
    for name in libs:
        if not name.endswith('/libapp.so'):
            assert old.read(name) == new.read(name), f'Native dependency changed: {name}'
    for name in protected:
        if '/assets/fonts/' in name or '/assets/audio/' in name:
            assert old.read(name) == new.read(name), f'Font/audio changed: {name}'
    for abi in ('armeabi-v7a', 'arm64-v8a', 'x86_64'):
        for lib in ('libapp.so', 'libflutter.so'):
            assert f'base/lib/{abi}/{lib}' in new_names, (abi, lib)
    catalogs = sorted(n for n in new_names if '/assets/i18n/ui/' in n and n.endswith('.json'))
    assert len(catalogs) == 34
    for name in catalogs:
        assert old.read(name) == new.read(name), f'Catalog changed: {name}'

with args.size_csv.open(encoding='utf-8-sig') as stream:
    rows = list(csv.DictReader(stream))
assert rows and {r['ABI'] for r in rows} == {'armeabi-v7a', 'arm64-v8a', 'x86_64'}
assert all(int(row['MAX']) <= args.max_bytes for row in rows), rows
print(json.dumps({
    'budget_bytes': args.max_bytes,
    'download_estimates': rows,
    'preserved_asset_and_native_paths': len(protected),
    'native_libraries': libs,
    'unchanged_language_catalogs': len(catalogs),
}, indent=2))
