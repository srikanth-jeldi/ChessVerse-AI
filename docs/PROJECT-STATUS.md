# ChessVerse Project Status

Updated: 2026-06-27

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
- Phone registration API, E.164 normalization and SMS gateway contract
- Stockfish-backed AI endpoint with ten calibrated levels
- Spring Boot, PostgreSQL/H2, Flyway, Docker and Kubernetes foundations
- GitHub Actions tests and backend container publishing

## Remaining Production Work

- Configure a real SMS provider for phone OTP
- Configure and verify Google and Apple OAuth
- Build Redis-backed worldwide matchmaking and authenticated WebSockets
- Add server-authoritative chess rules, clocks, reconnect and anti-cheat
- Generate Android and iOS Flutter platform projects
- Add push notifications, crash reporting, analytics and privacy controls
- Complete AWS managed database, Redis, secrets, TLS and observability
- Add store signing, subscriptions, legal pages and release-device testing
- Expand accessibility, localization, performance and security testing

## Next Milestone

The next production milestone should be native Android/iOS scaffolding plus
server-authoritative online matchmaking. Phone OTP can be enabled independently
as soon as an SMS provider and credentials are selected.
