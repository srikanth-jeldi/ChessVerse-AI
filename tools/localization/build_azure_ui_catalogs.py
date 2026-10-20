"""Translate missing static UI copy using a local, Git-ignored Azure key.

Only app-owned labels leave this machine. Credentials are never logged or
bundled. Existing translations and reviewed overrides are preserved.
"""
import collections
import html
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "mobile/assets/i18n/ui"
CACHE = ROOT / ".build-tmp/ui-translation-cache"
TOKEN = re.compile(r"\{\d+\}")
BRAND = re.compile(r"ChessVerseAI|CHESSVERSEAI|ChessVerse")
PROTECTED = re.compile(r"\{\d+\}|ChessVerseAI|CHESSVERSEAI|ChessVerse")


def brands_preserved(source, value):
    return collections.Counter(BRAND.findall(source)) == collections.Counter(BRAND.findall(value))
# Product names, file formats and score units remain unchanged intentionally.
UNCHANGED = {
    "CHESSVERSEAI", "CHESSVERSEAI ELO", "ChessVerse", "ChessVerseAI",
    "AI", "GIF", "FEN (.fen)", "PGN (.pgn)", "VS", "ELO",
    "+{0} XP", "{0} XP", "{0} CP", "{0} / {1} CP",
    "{0} • {1} • {2}cp", "~{0} Elo",
}
# Short labels sometimes look like names to MT. Give equivalent chess context
# while retaining the original lookup key and every interpolation parameter.
CONTEXT = {
    "Show AI Coach": "Display the chess coach",
    "Challenge Now": "Challenge this player now",
    "AI Review My Game": "Review my chess game with AI",
    "3D CITY REWARD VAULT • {0}": "Rewards in the 3D city • {0}",
    "CHESSVERSEAI MATCHMAKING": "Find a chess opponent in CHESSVERSEAI",
    "ChessVerseAI Email": "Email address for ChessVerseAI",
    "UNLOCKED": "Unlocked",
    "{0} · Due {1}": "{0} · Scheduled for review: {1}",
    "3 MASTERED": "3 exercises mastered",
    "BOARD {0}": "Chessboard {0}",
    "MATE 1": "Checkmate in one move",
    "CUSTOM AI • {0} ELO": "Custom computer opponent • {0} ELO",
    "PUZZLE RUSH RECORDS": "Records for timed chess puzzles",
    "SPEED ARENA": "Speed chess arena",
    "RIVAL FOUND": "Opponent found",
    "RIVAL": "Opponent",
    "RUSH": "Timed puzzles",
    "REPLAY": "Replay the game",
    "TOP {0} OF {1}": "Rank {0} out of {1}",
    "LINK": "Link account",
    "AI PERSONAS": "AI coach personalities",
    "Game Over": "The game has ended",
    "Draw!": "The game is a draw!",
    "Random Match": "Play against a random opponent",
    "Coach on": "Coach enabled",
    "Refresh academy": "Reload the chess academy",
    "LIVE POOL": "Players currently waiting",
    "Start Match": "Start the chess match",
    "King Safety": "Protecting the king",
    "Pass & Play": "Two players on one device",
    "FAIR PLAY": "Play fairly",
    "{0} • {1} ply • {2}": "{0} • {1} half-moves • {2}",
}


class PlainText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_data(self, data):
        self.parts.append(data)


def translate(batch, language, config):
    target = {"zh": "zh-Hans"}.get(language, language)
    endpoint = config.get("endpoint", "").rstrip("/")
    if endpoint != "https://api.cognitive.microsofttranslator.com":
        raise ValueError("Expected the global Translator HTTPS endpoint")
    texts = []
    for source in batch:
        text = html.escape(CONTEXT.get(source, source))
        text = PROTECTED.sub(lambda m: '<span class="notranslate">' + m[0] + "</span>", text)
        texts.append({"Text": text})
    url = endpoint + "/translate?" + urllib.parse.urlencode({
        "api-version": "3.0", "from": "en", "to": target, "textType": "html",
    })
    headers = {"Ocp-Apim-Subscription-Key": config["key"].strip(),
               "Content-Type": "application/json"}
    if config.get("region") and config["region"].lower() != "global":
        headers["Ocp-Apim-Subscription-Region"] = config["region"]
    for attempt in range(4):
        request = urllib.request.Request(
            url, data=json.dumps(texts).encode("utf-8"), headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                result = json.load(response)
            break
        except urllib.error.HTTPError as error:
            # Do not print request headers or credential-bearing config.
            if error.code not in (429, 500, 502, 503, 504) or attempt == 3:
                raise RuntimeError(f"Translator HTTP {error.code}") from None
            time.sleep(min(30, 5 * (attempt + 1)))
    if len(result) != len(batch):
        raise ValueError("Translator returned an unexpected batch length")
    values = []
    for source, item in zip(batch, result):
        parser = PlainText()
        parser.feed(item["translations"][0]["text"])
        value = "".join(parser.parts).strip()
        if not value or collections.Counter(TOKEN.findall(source)) != collections.Counter(TOKEN.findall(value)):
            raise ValueError(f"Invalid translation placeholders: {language}: {source}")
        if not brands_preserved(source, value):
            raise ValueError(f"Translated product name: {language}: {source}")
        values.append(value)
    return values


def main():
    config = json.loads((ROOT / ".build-tmp/azure-translator.local.json").read_text(encoding="utf-8-sig"))
    if not config.get("key", "").strip():
        raise ValueError("Translator key is not configured")
    sources = json.loads((OUT / "en.json").read_text(encoding="utf-8"))
    overrides = json.loads((Path(__file__).parent / "ui_overrides.json").read_text(encoding="utf-8"))
    for path in sorted(OUT.glob("*.json")):
        language = path.stem
        if language == "en":
            continue
        catalog = json.loads(path.read_text(encoding="utf-8"))
        cache_path = CACHE / path.name
        if cache_path.exists():
            cached = json.loads(cache_path.read_text(encoding="utf-8"))
            catalog = {**cached, **catalog}
        missing = [
            key for key in sources
            if key not in catalog or not brands_preserved(key, catalog[key]) or (
                language != "te" and catalog[key] == key and key not in UNCHANGED
                and re.search(r"[A-Za-z]", key)
            )
        ]
        for offset in range(0, len(missing), 20):
            batch = missing[offset:offset + 20]
            started = time.monotonic()
            catalog.update(zip(batch, translate(batch, language, config)))
            cache_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"{language}: translated {min(offset + 20, len(missing))}/{len(missing)} missing labels", flush=True)
            # F0 allows roughly 33,300 characters/minute; keep well below this.
            time.sleep(max(0, sum(len(text) for text in batch) / 400 - (time.monotonic() - started)))
        catalog.update(overrides.get(language, {}))
        if language == "te":
            catalog.update(json.loads((Path(__file__).parent / "ui_te_overrides.json").read_text(encoding="utf-8")))
        output = {key: catalog[key] for key in sources}
        for key, value in output.items():
            if not brands_preserved(key, value):
                raise ValueError(f"Override translated product name: {language}: {key}")
        path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"{language}: saved {len(output)} labels", flush=True)


if __name__ == "__main__":
    main()
