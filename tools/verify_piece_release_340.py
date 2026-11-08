"""Verify release 340 packaged art and retained native libraries against 339."""
from pathlib import Path
import hashlib
import json
import zipfile

root = Path(__file__).resolve().parents[1]
bundle = root/'release-output/1.3.73-340/ChessVerseAI-1.3.73-340.aab'
baseline = root/'release-output/1.3.72-339/ChessVerseAI-1.3.72-339.aab'
with zipfile.ZipFile(bundle) as new, zipfile.ZipFile(baseline) as old:
    natives = [n for n in old.namelist() if n.startswith('base/lib/') and n.endswith('.so')]
    assert set(natives) == {n for n in new.namelist() if n.startswith('base/lib/') and n.endswith('.so')}
    # libapp includes the new version string; third-party native files must survive.
    for n in natives:
        if not n.endswith('/libapp.so'):
            assert new.read(n) == old.read(n), n
    prefix='base/assets/flutter_assets/'
    assets=list((root/'mobile/assets/pieces').glob('staunton_*.png'))
    assets+=list((root/'mobile/assets/pieces/premium_individual').glob('*/*/*.webp'))
    assets+=list((root/'mobile/assets/pieces/premium_individual/mobile-readable').glob('*/*/*.webp'))
    assert len(assets)==156
    for p in assets:
        path=prefix+p.relative_to(root/'mobile').as_posix()
        assert new.read(path)==p.read_bytes(), path
    catalogues=[n for n in old.namelist() if '/i18n/' in n and n.endswith('.json')]
    assert len(catalogues) >= 34
    for n in catalogues:
        assert new.read(n)==old.read(n),n
report={'version':'1.3.73+340','runtime_piece_assets_verified':len(assets),
        'native_library_paths_preserved':len(natives),
        'unchanged_catalogues':len(catalogues),
        'sha256':hashlib.sha256(bundle.read_bytes()).hexdigest().upper(),
        'aab_bytes':bundle.stat().st_size}
(bundle.parent/'asset-verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
