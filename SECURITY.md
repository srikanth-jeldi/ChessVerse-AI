# Security Policy

## Supported Code

Security fixes target the current `main` branch until versioned mobile releases
are published.

## Reporting a Vulnerability

Do not open a public issue containing credentials, personal data, exploit code,
or an unpatched vulnerability. Contact the repository owner privately and
include the affected commit, platform, reproduction steps, likely impact, and
suggested mitigation when known.

Rotate an exposed credential immediately. Removing it from a later commit does
not remove it from Git history.

## Repository Rules

- Never commit `.env`, signing keys, provisioning profiles, service-account
  files, production database URLs, SMTP credentials, or API tokens.
- Android upload keys and Apple signing assets stay in protected storage.
- Production mobile builds use HTTPS only.
- Authentication tokens use Android Keystore or Apple Keychain storage.
- Server processes need authentication, rate limits, timeouts, and resource
  limits before public deployment.

## Release Gate

A public build is blocked until tests pass, dependency and secret scans are
clean, the backend is server-authoritative, privacy disclosures are complete,
and release artifacts are signed with production-controlled identities.
