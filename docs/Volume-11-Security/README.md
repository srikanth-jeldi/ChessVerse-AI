# Volume 11 – Security Architecture

## Scope and trust boundaries

Flutter clients are untrusted; Caddy is the public TLS boundary; the Spring API
is the authorization/validation boundary; PostgreSQL and attachment volumes are
private backend-only storage. Database and backend ports are never public.

## Identity and sessions

- Passwords use BCrypt cost 12. OAuth identities bind by provider subject, not
  silently by matching email.
- Access and refresh tokens contain 256 random bits; only SHA-256 hashes are
  stored. Refresh rotation is database-locked and reuse revokes the token family.
- Users can inspect/revoke device sessions or sign out everywhere.
- Browser WebSockets use 30-second, match/player-bound, single-use tickets.
- Auth and global API limits use atomic PostgreSQL buckets across replicas.

## Authorization and input controls

Each protected object operation verifies ownership or participation server
side. Client-provided IDs never confer access. Uploads are capped at 10 MiB,
inspected by magic bytes and image dimensions, server-renamed, and stored
outside the web root. Only JPEG, PNG, WebP, and PDF are accepted. Downloads
require conversation membership and send attachment disposition, `nosniff`,
CSP sandbox, and `private, no-store`.

## Data protection and keys

- TLS/WSS protects transit; mobile secrets use platform secure storage.
- Attachments use AES-256-GCM with a random per-object nonce and message ID as
  authenticated context. Existing plaintext files are atomically migrated.
- PostgreSQL dumps stream directly into `age`; no plaintext dump is retained.
  The private identity stays off the VPS and separate from backup storage.
- Production secrets live in the VPS environment or read-only mounts. Key
  rotation re-encrypts data before the prior key is retired.

## Operations and verification

Tokens, authorization headers, chat bodies, and attachment contents must not be
logged. Security signals include auth failures, throttling, rejected uploads,
health, and restarts. CI runs tests plus Gitleaks, Trivy, OWASP
Dependency-Check, and CodeQL. Release gates include replay/IDOR/malicious-upload
tests, encrypted restore drills, and k6 latency/error thresholds.

## Residual risk and response

Provider consoles still require least privilege, MFA, key restrictions,
immutable/versioned backup retention, and alert routing. Suspected exposure
triggers key rotation, session-family revocation, containment, log review,
required notification, and a documented post-incident review.

Firebase mobile API keys are public client identifiers and are intentionally
allowlisted only in the platform configuration files. Before every production
release, verify Android package/SHA restrictions, iOS bundle restrictions,
enabled-API restrictions, Firebase App Check enforcement, and quota alerts in
Google/Firebase Console; repository scanning cannot verify console state.
