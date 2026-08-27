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

Pending production deployment and repeat of the identical bounded scenario.

## Quota concurrency

Pending a 35-request single-user concurrency run. The acceptance result is exactly
30 successful requests and 5 HTTP 429 responses for the configured daily quota.

