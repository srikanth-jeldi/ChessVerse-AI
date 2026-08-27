"""Validate AI Coach input and authentication rejection paths in an approved environment."""

import argparse
import json
import urllib.error
import urllib.request
import uuid


START = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"


def request(base_url: str, path: str, *, method: str = "POST", token: str | None = None,
            body: dict | None = None) -> tuple[int, dict]:
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    call = urllib.request.Request(
        base_url.rstrip("/") + path,
        method=method,
        headers=headers,
        data=None if body is None else json.dumps(body).encode(),
    )
    try:
        with urllib.request.urlopen(call, timeout=30) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            payload = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            payload = {}
        return error.code, payload


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-url", required=True)
    args = parser.parse_args()
    token = None
    results = []
    try:
        status, auth = request(args.base_url, "/api/auth/guest", body={
            "installationId": str(uuid.uuid4()),
        })
        if status != 200:
            raise RuntimeError(f"guest setup failed with HTTP {status}")
        token = auth["token"]
        valid = {
            "fen": START,
            "playedMove": "e2e4",
            "question": "Why is this move useful?",
            "candidateMoves": ["e2e4"],
        }
        cases = [
            ("missing bearer token", None, valid, {401}),
            ("invalid FEN", token, {**valid, "fen": "not-a-fen"}, {400}),
            ("illegal move", token, {**valid, "playedMove": "e2e5"}, {422}),
            ("malformed move", token, {**valid, "playedMove": "DROP"}, {400}),
            ("too many candidates", token,
             {**valid, "candidateMoves": ["e2e4", "d2d4", "g1f3", "c2c4"]}, {400}),
            ("oversized question", token, {**valid, "question": "x" * 501}, {400}),
            ("control-character FEN", token, {**valid, "fen": START + "\nquit"}, {400}),
        ]
        failed = False
        for name, credential, payload, expected in cases:
            actual, response = request(
                args.base_url, "/api/v1/coach/ask", token=credential, body=payload)
            passed = actual in expected
            failed = failed or not passed
            results.append({
                "case": name,
                "status": actual,
                "expected": sorted(expected),
                "passed": passed,
                "message": str(response.get("message", ""))[:160],
            })
        print(json.dumps({
            "cases": len(results),
            "passed": sum(item["passed"] for item in results),
            "unexpected5xx": sum(item["status"] >= 500 for item in results),
            "results": results,
        }, indent=2))
        if failed or any(item["status"] >= 500 for item in results):
            raise SystemExit(1)
    finally:
        if token:
            try:
                request(args.base_url, "/api/auth/account", method="DELETE", token=token)
            except Exception:
                pass


if __name__ == "__main__":
    main()
