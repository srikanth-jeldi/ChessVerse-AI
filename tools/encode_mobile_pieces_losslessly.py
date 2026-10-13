"""Encode mobile piece PNG sources as pixel-identical WebP runtime assets.

Run from any directory with Python and Pillow. PNG sources are retained for
artwork maintenance; pubspec.yaml explicitly bundles only the WebP outputs.
"""
from io import BytesIO
from pathlib import Path

from PIL import Image


def main():
    root = Path(__file__).resolve().parents[1]
    assets = root / "mobile/assets/pieces/premium_individual/mobile-readable"
    sources = sorted(assets.glob("*/*/*.png"))
    if len(sources) != 72:
        raise ValueError(f"Expected 72 mobile pieces, found {len(sources)}")
    before = after = 0
    for source in sources:
        with Image.open(source) as image:
            original = image.convert("RGBA")
        encoded = BytesIO()
        original.save(encoded, format="WEBP", lossless=True, exact=True, method=6)
        payload = encoded.getvalue()
        with Image.open(BytesIO(payload)) as decoded:
            if decoded.size != original.size or decoded.convert("RGBA").tobytes() != original.tobytes():
                raise ValueError(f"Pixel mismatch: {source}")
        if len(payload) >= source.stat().st_size:
            raise ValueError(f"Encoding did not reduce size: {source}")
        source.with_suffix(".webp").write_bytes(payload)
        before += source.stat().st_size
        after += len(payload)
    print(f"Verified {len(sources)} pixel-identical images: {before:,} -> {after:,} bytes")


if __name__ == "__main__":
    main()
