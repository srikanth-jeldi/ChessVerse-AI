"""Build-time translation of public UI labels; never called by the app.

Input is the parser's static-string inventory, not source code/account data.
Output is bundled offline JSON. Caches allow interrupted runs to resume.
Machine translations still require native-speaker editorial review.
"""
import concurrent.futures
import json
import re
import time
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANGS = "te hi ta kn ml mr bn gu pa ur ar es fr de it pt ru uk tr fa zh ja ko id ms th vi pl nl sv el he sw".split()
OUT = ROOT / "mobile/assets/i18n/ui"
CACHE = ROOT / ".build-tmp/ui-translation-cache"
OUT.mkdir(parents=True, exist_ok=True)
CACHE.mkdir(parents=True, exist_ok=True)
PHRASES = json.loads((ROOT / ".build-tmp/ui-copy-source.json").read_text(encoding="utf-8"))


def request(text, language):
    url = "https://translate.googleapis.com/translate_a/single?" + urllib.parse.urlencode({
        "client": "gtx", "sl": "en", "tl": language, "dt": "t", "q": text
    })
    for attempt in range(8):
        try:
            with urllib.request.urlopen(url, timeout=45) as response:
                data = json.load(response)
            return "".join(part[0] or "" for part in data[0])
        except Exception as error:
            if attempt == 7:
                raise
            time.sleep(min(300, 60 * (attempt + 1)) if
                       isinstance(error, urllib.error.HTTPError) and error.code == 429
                       else 2 ** attempt)


def translate_batch(batch, language):
    # Numbered lines make alignment verifiable even if the service joins segments.
    source = "\n".join(f"{i + 1000}: {text}" for i, text in enumerate(batch))
    translated = request(source, language)
    matches = list(re.finditer(r"(?m)^\s*(\d{4})\s*[:：.]\s*", translated))
    if len(matches) == len(batch) and [int(m[1]) for m in matches] == list(range(1000, 1000 + len(batch))):
        values = [
            translated[m.end():matches[i + 1].start() if i + 1 < len(matches) else None].strip()
            for i, m in enumerate(matches)
        ]
        if all(values):
            return values
    # Do not assign a neighbouring line's translation to a key.
    return [request(text, language).strip() for text in batch]


def build(language):
    cache_file = CACHE / f"{language}.json"
    catalog = json.loads(cache_file.read_text(encoding="utf-8")) if cache_file.exists() else {}
    if language == "te":
        catalog.update(json.loads((Path(__file__).parent / "ui_te_overrides.json").read_text(encoding="utf-8")))
    missing = [p for p in PHRASES if p not in catalog]
    batches, batch, length = [], [], 0
    for phrase in missing:
        if batch and (length + len(phrase) > 2200 or len(batch) >= 24):
            batches.append(batch)
            batch, length = [], 0
        batch.append(phrase)
        length += len(phrase) + 8
    if batch:
        batches.append(batch)
    for batch in batches:
        values = translate_batch(batch, language)
        if not all(values):
            raise RuntimeError(f"Empty translation in {language}")
        for i, (source, value) in enumerate(zip(batch, values)):
            expected = sorted(re.findall(r"\{\d+\}", source))
            if sorted(re.findall(r"\{\d+\}", value)) != expected:
                values[i] = request(source, language).strip()
            if sorted(re.findall(r"\{\d+\}", values[i])) != expected:
                raise RuntimeError(f"Translation changed placeholders: {language}: {source}")
        catalog.update(zip(batch, values))
        cache_file.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
        time.sleep(2)
    output = {p: catalog[p] for p in PHRASES}
    output.update(json.loads((Path(__file__).parent / "ui_overrides.json").read_text(encoding="utf-8")).get(language, {}))
    (OUT / f"{language}.json").write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{language}: {len(output)} labels", flush=True)


if __name__ == "__main__":
    (OUT / "en.json").write_text(json.dumps({p: p for p in PHRASES}, indent=2) + "\n", encoding="utf-8")
    with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
        for result in pool.map(build, LANGS):
            pass
