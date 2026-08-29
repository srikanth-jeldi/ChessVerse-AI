# ChessVerseAI security and load-test evidence

Date: 2026-08-29

## Release-gate results

| Gate | Result | Evidence |
| --- | --- | --- |
| Backend automated tests | Pass | Full Maven test suite completed with exit code 0. |
| Flutter automated tests | Pass | 170 of 170 tests passed. |
| Flutter static analysis | Pass | No errors or warnings; 18 informational style notices remain. |
| Authenticated API load test | Pass | 25 virtual users, 12,538 requests, 6,269 iterations, 0% failures, p95 99.28 ms, max 1.06 s. |
| Git-history secret scan | Pass | Gitleaks 8.28.0 reported zero unallowlisted findings. Firebase client identifiers and deterministic test-only fixtures have narrow, documented path allowlists. |
| Backend dependency scan | Pass | Trivy 0.66.0 reported zero fixed HIGH or CRITICAL findings. |
| Mobile dependency scan | Pass | Trivy 0.66.0 scan of `pubspec.lock` reported zero fixed HIGH or CRITICAL findings. |
| Session ownership/IDOR regression | Pass | Cross-account device-session revocation is rejected and covered by `AuthControllerTest`. |

The k6 profile ramps to 25 concurrent virtual users and checks liveness, authenticated identity, and community reads when enabled. Its committed thresholds are HTTP failure rate below 1%, p95 below 750 ms, and p99 below 1,500 ms.

## Continuous security gates

The GitHub security workflow runs Gitleaks, Trivy, OWASP Dependency-Check 12.2.2, and CodeQL. The local OWASP 12.1.8 run encountered the known long-NVD-URL database issue; 12.2.2 contains the upstream fix. A local 12.2.2 database refresh was too slow without an NVD API key, so the CI result remains the authoritative dependency-check gate.

## Production release checks

Before production is declared complete:

1. Verify Firebase Android/iOS app restrictions in Firebase and Google Cloud consoles.
2. Install the attachment encryption key only in the VPS secret environment.
3. Produce an age-encrypted database backup and complete a restore verification.
4. Confirm migrations, liveness, authentication, WebSocket tickets, tournaments, attachment round-trip, and deployed Git revision.
5. Configure a separate off-site backup destination; this requires storage-provider credentials and cannot be proven from source code alone.

## Scope statement

These results are automated engineering evidence, not a certification of a third-party penetration test. A formal independent penetration test and ongoing intrusion-alert operations require an external assessor/monitoring service and remain operational controls.
