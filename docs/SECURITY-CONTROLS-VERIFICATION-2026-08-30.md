# Security controls verification — 2026-08-30

## Scope and result

This verification covers the startup-cost controls that can be implemented and tested internally. It does not replace an independent penetration test.

- WebSocket cross-site protection: production uses the same explicit `ALLOWED_ORIGIN_PATTERNS` allow-list as HTTP CORS. A global `*` or empty list now fails application startup. Match sockets additionally require a short-lived, one-time, match-bound ticket (or Bearer authentication) and participant authorization.
- CSRF: the API does not authenticate with ambient cookies or server sessions. Protected endpoints require an explicit `Authorization: Bearer` header, so classical cookie-based CSRF is not applicable. If cookie authentication is introduced later, CSRF tokens and `SameSite` cookies become mandatory before release.
- Object authorization / IDOR: session revocation verifies ownership; match operations verify participation; direct-message history requires an accepted friendship; attachment download permits only the sender or recipient; analysis jobs are filtered by the authenticated player. Existing controller/service tests cover session ownership, game ownership, match participation, and tournament access. These controls must remain part of every endpoint review.
- Upload handling: attachments are limited to 10 MiB, detected by server-side magic bytes, restricted to JPEG/PNG/WebP/PDF, checked for malformed or excessive image dimensions, renamed independently of the supplied extension, encrypted at rest, and returned as downloads with `nosniff`, sandbox CSP, and `no-store`. Tests include disguised HTML, SVG active content, traversal/control characters, empty files, oversized files, and image-bomb dimensions.
- Sensitive logs: request bodies and authorization headers are not logged. The local OTP delivery logger no longer emits email addresses; OTPs, passwords, access tokens, refresh tokens, API keys, and attachment plaintext are not logged.
- Edge security: Caddy serves HSTS, CSP, frame restrictions, MIME sniffing protection, referrer policy, and permissions policy. Caddy's current TLS defaults provide modern TLS; this is also checked against the live endpoint before deployment evidence is closed.
- Abuse alerting: every distributed rate-limit rejection increments `chessverse_rate_limit_rejections_total`, tagged only with low-cardinality policy and scope. The five-minute production monitor raises the existing application heartbeat failure alert when the configured interval threshold is exceeded.

## Deferred / residual risk

- A professional independent penetration test remains deferred until budget is available.
- Signature and structural validation is not an antivirus engine. If arbitrary document formats or public uploads are introduced, add asynchronous malware scanning and quarantine before release.
- The CSP intentionally permits inline styles/scripts and WebAssembly evaluation required by the current Flutter web build. Tighten this with nonces/hashes when the generated web bundle supports them.
- Firebase App Check / Play Integrity enforcement should be enabled after telemetry confirms legitimate production clients are compatible.
