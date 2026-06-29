# ChessVerse Project Status

Updated: 2026-06-28

## Current Completion

- Playable web/Windows MVP: approximately 70%
- Production-ready worldwide product: approximately 40%

The current mobile screenshots are responsive Flutter Web. Native Android and
iOS project folders, store signing, release builds and device QA are not
present yet, so the project is not ready for Play Store or App Store submission.

## Delivered

- Responsive chess arena with five board themes and 3D Staunton assets
- Legal move highlighting, captures, castling, en passant and promotion
- Clocks, undo, move history, check/checkmate effects and result overlay
- Email registration, OTP verification and password login
- Phone registration, AWS SNS OTP delivery, verification and phone/password login
- AWS SNS sandbox phone verified with a successful end-to-end app OTP test
- Google client flow plus backend identity-token validation
- Stockfish-backed AI endpoint with ten calibrated levels
- Spring Boot, PostgreSQL/H2, Flyway, Docker and Kubernetes foundations
- GitHub Actions tests and backend container publishing

## Remaining Production Work

- Request AWS SMS production access and complete India sender/DLT registration
- Verify production email OTP delivery after rotating the exposed Gmail app password
- Complete live Google account QA on Web and Android
- Build Redis-backed worldwide matchmaking and authenticated WebSockets
- Add server-authoritative chess rules, clocks, reconnect and anti-cheat
- Generate Android and iOS Flutter platform projects
- Add push notifications, crash reporting, analytics and privacy controls
- Complete AWS managed database, Redis, secrets, TLS and observability
- Add store signing, subscriptions, legal pages and release-device testing
- Expand accessibility, localization, performance and security testing

## Next Milestone

The next production milestone is authentication production readiness: move AWS
SMS out of the sandbox, verify email delivery, and complete live Google
configuration. After that, build server-authoritative online matchmaking.
