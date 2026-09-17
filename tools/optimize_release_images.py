"""Optimize selected runtime images; retain originals in ignored build storage."""
from pathlib import Path
from PIL import Image
import shutil

root = Path(__file__).resolve().parents[1]
backup = root / '.build-tmp/image-originals'
backup.mkdir(parents=True, exist_ok=True)
for relative in ['branding/loading-cinematic-v1.png', 'backgrounds/master-games-hall-v1.png']:
    source = root / 'mobile/assets' / relative
    if not source.exists():
        continue
    shutil.copy2(source, backup / source.name)
    with Image.open(source) as img:
        img.thumbnail((1200, 1800), Image.Resampling.LANCZOS)
        img.convert('RGB').save(source.with_suffix('.webp'), 'WEBP', quality=85, method=6)
    print(f'{relative}: {source.stat().st_size:,} -> {source.with_suffix(".webp").stat().st_size:,} bytes')
    source.unlink()

source = root / 'mobile/assets/branding/app_icon.png'
original = backup / 'app_icon.png'
if not original.exists():
    shutil.copy2(source, original)
with Image.open(original) as img:
    img.thumbnail((512, 512), Image.Resampling.LANCZOS)
    img.convert('RGBA').quantize(colors=256, method=Image.Quantize.FASTOCTREE).save(source, optimize=True)
print(f'app_icon.png: {original.stat().st_size:,} -> {source.stat().st_size:,} bytes')

for folder in ['mobile/lib', 'mobile/test', 'mobile/web']:
    for path in (root / folder).rglob('*'):
        if path.suffix not in ['.dart', '.html', '.css']:
            continue
        text = path.read_text(encoding='utf-8')
        updated = text.replace('loading-cinematic-v1.png', 'loading-cinematic-v1.webp').replace('master-games-hall-v1.png', 'master-games-hall-v1.webp')
        if text != updated:
            path.write_text(updated, encoding='utf-8')
path = root / 'mobile/pubspec.yaml'
path.write_text(path.read_text(encoding='utf-8').replace('loading-cinematic-v1.png', 'loading-cinematic-v1.webp'), encoding='utf-8')
