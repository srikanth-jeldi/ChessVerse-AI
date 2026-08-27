"""Summarize longitudinal ChessVerseAI metric snapshots without user data."""

import argparse
import datetime as dt
import glob
import json


COUNTERS = (
    "chessverse_ai_coach_requests_total",
    "chessverse_ai_coach_quota_rejected_total",
    "chessverse_ai_coach_language_successes_total",
    "chessverse_ai_coach_language_failures_total",
    "chessverse_ai_coach_outcomes_resolved_total",
)


def parse_time(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def positive_delta(samples: list[dict], metric: str) -> tuple[float, int]:
    total = 0.0
    resets = 0
    previous = None
    for sample in samples:
        current = float(sample.get("metrics", {}).get(metric, 0.0))
        if previous is not None:
            if current >= previous:
                total += current - previous
            else:
                resets += 1
                total += current
        previous = current
    return total, resets


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("snapshots", help="Glob such as /var/log/chessverse-ai-metrics/*.json")
    parser.add_argument("--minimum-days", type=int, default=14)
    parser.add_argument("--minimum-samples", type=int, default=40)
    args = parser.parse_args()
    samples = []
    for path in sorted(glob.glob(args.snapshots)):
        with open(path, encoding="utf-8") as source:
            sample = json.load(source)
        sample["_captured"] = parse_time(sample["capturedAtUtc"])
        samples.append(sample)
    samples.sort(key=lambda item: item["_captured"])
    if not samples:
        raise SystemExit("no snapshots matched")
    span = samples[-1]["_captured"] - samples[0]["_captured"]
    deltas = {}
    reset_counts = []
    for metric in COUNTERS:
        delta, resets = positive_delta(samples, metric)
        deltas[metric] = round(delta, 2)
        reset_counts.append(resets)
    readiness_failures = sum(sample.get("readiness") != "UP" for sample in samples)
    enough = (span.total_seconds() >= args.minimum_days * 86400
              and len(samples) >= args.minimum_samples)
    print(json.dumps({
        "firstCapturedAtUtc": samples[0]["capturedAtUtc"],
        "lastCapturedAtUtc": samples[-1]["capturedAtUtc"],
        "spanDays": round(span.total_seconds() / 86400, 2),
        "samples": len(samples),
        "readinessFailures": readiness_failures,
        "counterResets": max(reset_counts, default=0),
        "counterDeltas": deltas,
        "minimumEvidenceDays": args.minimum_days,
        "minimumEvidenceSamples": args.minimum_samples,
        "evidenceSufficient": enough,
    }, indent=2))


if __name__ == "__main__":
    main()
