"""Concurrent smoke/load probe for the authenticated AI Coach endpoint.

Run only against an approved test account/environment because requests consume the
account's configured daily coach quota.
"""

import argparse
import json
import statistics
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"


def request_once(base_url: str, token: str) -> tuple[int, float]:
    body = json.dumps({
        "fen": START,
        "playedMove": "e2e4",
        "question": "Compare e2e4, d2d4 and g1f3.",
        "candidateMoves": ["e2e4", "d2d4", "g1f3"],
    }).encode()
    request = urllib.request.Request(
        base_url.rstrip("/") + "/api/v1/coach/ask",
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            response.read()
            status = response.status
    except urllib.error.HTTPError as error:
        error.read()
        status = error.code
    return status, (time.perf_counter() - started) * 1000


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, round((len(ordered) - 1) * fraction))]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    credentials = parser.add_mutually_exclusive_group(required=True)
    credentials.add_argument("--token")
    credentials.add_argument("--token-file", help="UTF-8 file containing one bearer token per line")
    parser.add_argument("--requests", type=int, default=20)
    parser.add_argument("--concurrency", type=int, default=4)
    args = parser.parse_args()
    tokens = ([args.token] if args.token else [
        line.strip() for line in Path(args.token_file).read_text(encoding="utf-8").splitlines()
        if line.strip()
    ])
    if not tokens:
        parser.error("at least one token is required")
    results = []
    with ThreadPoolExecutor(max_workers=args.concurrency) as pool:
        futures = [
            pool.submit(request_once, args.base_url, tokens[index % len(tokens)])
            for index in range(args.requests)
        ]
        for future in as_completed(futures):
            results.append(future.result())
    latencies = [latency for _, latency in results]
    statuses = {status: sum(1 for actual, _ in results if actual == status) for status, _ in results}
    report = {
        "requests": len(results),
        "users": len(tokens),
        "concurrency": args.concurrency,
        "statuses": statuses,
        "latencyMs": {
            "average": round(statistics.mean(latencies), 1),
            "p50": round(percentile(latencies, 0.50), 1),
            "p95": round(percentile(latencies, 0.95), 1),
            "maximum": round(max(latencies), 1),
        },
    }
    print(json.dumps(report, indent=2))
    unexpected = [status for status, _ in results if status not in (200, 429)]
    if unexpected:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
