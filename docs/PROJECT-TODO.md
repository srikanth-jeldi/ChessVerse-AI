# ChessVerse AI - Product and Security TODO

Last reviewed: 2026-08-29

## Release gate: complete before public tournaments

### P0 - Tournament integrity and authorization

- [ ] Define tournament formats for v1: Swiss, arena, knockout, or a deliberately smaller first release.
- [ ] Add an explicit tournament state machine: `DRAFT -> REGISTRATION_OPEN -> RUNNING -> COMPLETED/CANCELLED`.
- [ ] Enforce registration window, capacity, eligibility, bans, rating range, and one-entry-per-player rules inside a database transaction.
- [ ] Prevent join/withdraw after the configured deadline; never trust client-supplied status or timestamps.
- [ ] Add admin/organizer roles and server-side authorization for create, edit, start, pause, cancel, remove-player, and adjudicate actions.
- [ ] Add immutable audit events for all organizer actions and sensitive tournament state transitions.
- [ ] Make start/round generation idempotent so retries cannot create duplicate pairings or games.
- [ ] Add database constraints and locking to prevent duplicate pairings, double results, over-capacity registration, and concurrent state corruption.
- [ ] Connect tournament games to authoritative online matches; accept results only from the game server, never directly from clients.
- [ ] Define disconnect, no-show, timeout, draw, resignation, abort, rematch, and dispute rules.
- [ ] Add fair-play holds and an adjudication flow before prizes/ratings become final.
- [ ] Add server-side standings with deterministic tie-breaks and publish the tie-break rules in the UI.
- [ ] Add integration tests for concurrent joins, full capacity, late join/withdraw, duplicate round start, forged result, reconnect, and cancellation.

### P0 - Upload and attachment safety

- [ ] Replace client-provided MIME trust with server-side content detection using file signatures/magic bytes.
- [ ] Start with a strict allow-list (for example JPEG, PNG, WebP, and PDF only); reject HTML, SVG, scripts, executables, archives, and polyglot files.
- [ ] Decode and re-encode accepted images to remove active content and metadata; reject malformed/decompression-bomb images.
- [ ] Generate storage names on the server; never use a user filename as a path. Normalize download filenames and prevent traversal.
- [ ] Enforce size limits both at the reverse proxy and application layers, plus per-user upload quotas and rate limits.
- [ ] Store attachments outside the web root and always download with `Content-Disposition: attachment`, `X-Content-Type-Options: nosniff`, and a safe server-selected content type.
- [ ] Add malware scanning/quarantine before an attachment becomes downloadable.
- [ ] Verify sender/recipient authorization on every download and ensure deleted accounts/messages remove associated files according to retention policy.
- [ ] Add malicious upload tests: fake MIME, SVG/HTML, double extension, path traversal, oversized file, image bomb, and unauthorized download.

### P0 - Authentication, sessions, and API abuse

- [ ] Replace the single-process auth limiter with a Redis/distributed rate limiter keyed by IP, account, device, and action.
- [ ] Add global and endpoint-specific limits for login, signup, password reset, chat, uploads, matchmaking, moves, tournament join, and admin actions.
- [ ] Return consistent `429` responses with `Retry-After`; add metrics and alerts for throttling spikes.
- [ ] Shorten access-token lifetime; implement refresh-token rotation, reuse detection, server-side revocation, logout-all, and per-device session listing.
- [ ] Remove WebSocket tokens from query strings. Use an `HttpOnly; Secure; SameSite` cookie for web or an authenticated short-lived one-time WebSocket ticket.
- [ ] Redact credentials, tokens, query strings, authorization headers, attachment names, and sensitive chat data from application/proxy/error logs.
- [ ] Add MFA for administrators first, then optional TOTP/passkeys for players.
- [ ] Add CSRF protection where cookie authentication is used and strict WebSocket `Origin` allow-list validation.
- [ ] Add authorization/IDOR tests for all messages, attachments, games, tournament, and admin endpoints.

### P0 - Data protection and recovery

- [ ] Document the threat model and decide which fields need application-level envelope encryption (chat bodies, attachment metadata, sensitive identifiers).
- [ ] Encrypt attachment objects with per-object data keys and a managed master key/KMS; define key rotation and deletion behavior.
- [ ] Enable encrypted PostgreSQL storage/volume and encrypted backups; do not keep encryption keys beside backups.
- [ ] Send encrypted backups to a separate account/provider with least-privilege credentials, retention, immutability/versioning, and deletion protection.
- [ ] Automate backup success/failure alerts and perform a documented restore drill before release.
- [ ] Define RPO/RTO, retention periods, legal/security holds, account deletion behavior, and backup expiry behavior.

## P1 - Tournament v1 implementation

- [ ] Finalize the smallest shippable format. Recommended first release: scheduled Swiss with fixed rounds and no cash prizes.
- [ ] Extend schema with format, visibility, rated flag, rating bounds, registration times, round count, organizer, version, and rules.
- [ ] Add tournament round, pairing, result, standing snapshot, audit event, and dispute tables.
- [ ] Build organizer APIs and an admin UI for draft/create/edit/publish/start/cancel/adjudicate.
- [ ] Build player screens: details/rules, countdown, join/withdraw, participants, pairings, current game, standings, and results.
- [ ] Add a scheduler/worker for registration close, round start/end, reminders, no-shows, and completion. Use distributed locking.
- [ ] Implement deterministic Swiss pairing with repeat-opponent avoidance, color balancing, byes, and reproducible tests.
- [ ] Integrate rating updates exactly once after result finalization; make recalculation/reversal auditable.
- [ ] Add push/in-app notifications for registration, upcoming start, pairing, round deadline, result, dispute, and completion.
- [ ] Add moderation tools: suspend entry, chat/report handling, fair-play review queue, and appeal notes.
- [ ] Add observability dashboards for registration failures, scheduler lag, active games, result conflicts, abuse, and WebSocket health.
- [ ] Load-test expected tournament concurrency, join bursts, standings reads, reconnect storms, and notification fan-out.

## P1 - Security engineering and evidence

- [ ] Replace `docs/Volume-11-Security/README.md` placeholder with architecture, data-flow and trust-boundary diagrams, threat model, control owners, and incident playbook.
- [ ] Add CI dependency/CVE scanning for Maven, Flutter/Dart, Docker images, and GitHub Actions; fail builds on policy-defined critical findings.
- [ ] Add secret scanning, SAST, container/IaC scanning, and SBOM generation to CI.
- [ ] Pin/regularly update dependencies and GitHub Actions; document vulnerability patch SLAs.
- [ ] Configure centralized security logs, alert routing, uptime checks, anomalous-login alerts, upload-abuse alerts, and admin-action alerts.
- [ ] Add production headers/TLS validation: HSTS, CSP for web, frame restrictions, referrer policy, permissions policy, and modern TLS only.
- [ ] Verify Firebase/Google API key restrictions in Console: exact Android package + SHA certificates, exact web origins, API allow-list, quotas, and App Check where supported.
- [ ] Ensure Firebase service-account credentials and signing keys are never in the repository or images; rotate any exposed server secret.
- [ ] Commission an independent penetration test after P0 controls and tournament v1 are staging-complete; track remediation evidence.

## P2 - Account and privacy maturity

- [ ] Add verified email change, password change, session/device history, remote session revoke, and suspicious-login notifications.
- [ ] Add export-my-data and verified account deletion jobs with measurable completion and attachment cleanup.
- [ ] Add user blocking/reporting, chat spam controls, tournament conduct enforcement, and moderator case history.
- [ ] Review privacy policy/data-safety disclosures against actual retention, encryption, analytics, crash reporting, backups, and subprocessors.
- [ ] Establish recurring access reviews, key rotation drills, incident tabletop exercises, and quarterly restore tests.

## Definition of done for tournament launch

- [ ] All P0 items are implemented and verified in staging.
- [ ] Tournament state/result integrity integration tests pass, including concurrency and forged-request cases.
- [ ] Restore drill succeeds from an encrypted off-site backup within the documented RTO.
- [ ] Critical/high dependency, SAST, secret, container, and penetration-test findings are resolved or formally risk-accepted.
- [ ] Monitoring and alerts are exercised, and an on-call/incident owner is named.
- [ ] Legal rules, privacy disclosures, fair-play policy, prizes (if any), refunds, and dispute process are published.
- [ ] Staged rollout completed: internal test -> invite-only event -> capped public beta -> general availability.
