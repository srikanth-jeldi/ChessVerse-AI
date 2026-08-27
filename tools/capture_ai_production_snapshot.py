"""Capture a PII-free ChessVerseAI health and AI-observability snapshot."""

import argparse
import datetime as dt
import json
import urllib.request


METRICS = {
    "chessverse_ai_coach_requests_total",
    "chessverse_ai_coach_quota_rejected_total",
    "chessverse_ai_coach_cache_hits_total",
    "chessverse_ai_coach_engine_review_cache_hits_total",
    "chessverse_ai_coach_structured_fallbacks_total",
    "chessverse_ai_coach_language_successes_total",
    "chessverse_ai_coach_language_failures_total",
    "chessverse_ai_coach_outcomes_resolved_total",
    "process_uptime_seconds",
}


def read(url: str) -> bytes:
    with urllib.request.urlopen(url, timeout=20) as response:
        return response.read()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--output")
    args = parser.parse_args()
    base = args.base_url.rstrip("/")
    health = json.loads(read(base + "/actuator/health/readiness"))
    raw_metrics = read(base + "/actuator/prometheus").decode("utf-8", errors="replace")
    values = {}
    for line in raw_metrics.splitlines():
        if not line or line.startswith("#") or " " not in line:
            continue
        name, raw = line.split(" ", 1)
        if "{" in name:
            name = name.split("{", 1)[0]
        if name in METRICS:
            try:
                values[name] = float(raw.strip())
            except ValueError:
                continue
    snapshot = {
        "capturedAtUtc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "baseUrl": base,
        "readiness": health.get("status"),
        "metrics": {name: values.get(name, 0.0) for name in sorted(METRICS)},
    }
    encoded = json.dumps(snapshot, indent=2) + "\n"
    if args.output:
        with open(args.output, "w", encoding="utf-8") as target:
            target.write(encoded)
    print(encoded, end="")
    if snapshot["readiness"] != "UP":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
