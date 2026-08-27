"""Create disposable guests, run the AI Coach load probe, then delete them.

Tokens remain in process memory and every successfully created account is removed in
a finally block. Use only against an explicitly approved environment.
"""

import argparse
import json
import statistics
import sys
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ai_coach_load_test import percentile, request_once  # noqa: E402


def call(base_url: str, path: str, *, method: str = "POST", token: str | None = None,
         body: dict | None = None) -> dict:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        base_url.rstrip("/") + path,
        method=method,
        headers=headers,
        data=None if body is None else json.dumps(body).encode(),
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = response.read()
        return json.loads(payload) if payload else {}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--users", type=int, default=4)
    parser.add_argument("--requests", type=int, default=12)
    parser.add_argument("--concurrency", type=int, default=4)
    args = parser.parse_args()
    tokens: list[str] = []
    try:
        for _ in range(args.users):
            response = call(args.base_url, "/api/auth/guest", body={
                "installationId": str(uuid.uuid4()),
            })
            tokens.append(response["token"])
        results = []
        with ThreadPoolExecutor(max_workers=args.concurrency) as pool:
            futures = [
                pool.submit(request_once, args.base_url, tokens[index % len(tokens)])
                for index in range(args.requests)
            ]
            for future in as_completed(futures):
                results.append(future.result())
        latencies = [latency for _, latency in results]
        statuses = {
            status: sum(1 for actual, _ in results if actual == status)
            for status, _ in results
        }
        print(json.dumps({
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
        }, indent=2))
        if any(status not in (200, 429) for status, _ in results):
            raise SystemExit(1)
    finally:
        for token in tokens:
            try:
                call(args.base_url, "/api/auth/account", method="DELETE", token=token)
            except Exception:
                pass


if __name__ == "__main__":
    main()
