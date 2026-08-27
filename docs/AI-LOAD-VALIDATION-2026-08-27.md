# AI Coach load validation — 2026-08-27

Production endpoint: `https://api.chessverseai.com/api/v1/engine/coach`

## Baseline

- 4 isolated guest users
- 12 requests, concurrency 4
- 3 candidate moves evaluated per request
- HTTP results: 12/12 successful
- Average: 20,207.7 ms
- p50: 20,095.7 ms
- p95: 22,963.1 ms
- Maximum: 24,250.3 ms

This baseline exposed repeated identical Stockfish work across requests. The backend
now uses a bounded, expiring Caffeine cache that also coalesces concurrent loads for
the same FEN and candidate move. Production results after deployment are recorded
below.

## Post-optimization

- 4 isolated guest users
- 12 requests, concurrency 4
- HTTP results: 12/12 successful
- Average: 1,683.0 ms (91.7% lower than baseline)
- p50: 70.2 ms
- p95: 4,934.9 ms (78.5% lower than baseline)
- Maximum: 4,935.3 ms

Production metrics reported 87 engine-review cache hits after the validation runs.

## Quota concurrency

- 1 isolated guest user
- 35 requests, concurrency 8
- HTTP results: exactly 30 successful and 5 HTTP 429 responses
- No quota bypass and no unexpected HTTP response
- Live quota-rejection metric: 5

All disposable guest accounts created by both scenarios were deleted in a `finally`
cleanup path. The first quota run correctly enforced 30 requests but exposed five
incorrect HTTP 500 responses; that exception mapping was fixed and the acceptance
scenario above was rerun successfully.
