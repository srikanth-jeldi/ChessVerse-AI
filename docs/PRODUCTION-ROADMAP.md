# ChessVerse AI Production Roadmap

**Status:** Sprint 1 foundation started  
**Target platforms:** Android, iOS, tablets, desktop, web  
**Backend direction:** Java 21 Spring Boot modular monolith, PostgreSQL, Redis, WebSocket, Stockfish, AI coach  
**Cloud direction:** Docker, GitHub Actions, AWS EKS, RDS, ElastiCache, CloudWatch

## Current Repository State

The repository now has a first implementation foundation:

- `backend/`: Spring Boot API with health endpoint, game creation, move recording, validation, persistence model, Flyway migration, and controller test.
- `mobile/`: Flutter app shell with responsive chess board, move history, AI action controls, and widget test.
- `.github/workflows/ci.yml`: Backend tests, Flutter analyze/tests, and backend Docker image publishing.
- `docker-compose.yml`: Local PostgreSQL, Redis, and backend runtime.
- `infrastructure/k8s/`: Kubernetes namespace, backend deployment/service, ingress, and secret template.

## Engineering Principles

- Keep the backend modular monolith until traffic or team boundaries require microservices.
- Use a proven chess rules engine instead of hand-rolling legal move generation.
- Keep Stockfish as a bounded engine adapter with timeouts, depth limits, and resource controls.
- Treat AI coach output as explainable guidance, not a source of chess truth.
- Design every feature for mobile first, then adapt layouts for tablet, desktop, and web.
- All production secrets must live outside Git in GitHub Actions secrets, AWS Secrets Manager, or Kubernetes secrets.

## Phase 1: Playable MVP

Goal: A stable offline and AI chess experience.

- Replace placeholder board movement with legal move validation.
- Add game state derived from FEN and PGN.
- Add undo, resign, draw, check, checkmate, stalemate, and promotion flows.
- Integrate Stockfish locally for Flutter where platform permits, and via backend for cloud analysis.
- Add AI difficulty levels 1-10 using depth, time, and controlled inaccuracies.
- Add polished animations: piece movement, captures, check highlight, promotion picker, game-over modal.
- Add backend API contracts for games, moves, analysis, and coach explanations.

## Phase 2: Accounts and Cloud Sync

Goal: Users can save progress and resume across devices.

- Add JWT authentication with refresh tokens.
- Add user profile, settings, avatar, country, and rating fields.
- Persist games, move history, analysis summaries, and learning progress.
- Add API rate limiting and audit logging.
- Add privacy controls and account deletion.

## Phase 3: AI Coach and Learning

Goal: Make the app feel intelligent and useful for improvement.

- Add blunder, mistake, inaccuracy, best move, and missed tactic classification.
- Generate coach explanations from Stockfish lines plus curated chess teaching prompts.
- Add practice modules: tactics, openings, endgames, checkmates, and custom drills.
- Add puzzle ingestion and tagging.
- Add learning path progress and daily goals.

## Phase 4: Multiplayer

Goal: Real-time online games.

- Add WebSocket game rooms.
- Add matchmaking by rating and time control.
- Add reconnection support, clocks, premove support, and anti-abuse controls.
- Add leaderboards, tournaments, and fair-play review signals.

## Phase 5: Store and Production Readiness

Goal: Release-ready Android, iOS, desktop, and web builds.

- Add app icons, splash screens, signed Android and iOS builds.
- Add crash reporting, analytics, and performance monitoring.
- Complete accessibility pass for contrast, touch targets, keyboard navigation, and screen readers.
- Add release channels: dev, staging, production.
- Add Play Store and App Store metadata, screenshots, privacy policy, and support URLs.

## AWS Target Architecture

- EKS for backend workloads.
- RDS PostgreSQL for relational data.
- ElastiCache Redis for sessions, matchmaking queues, and rate limiting.
- S3 for exported PGNs, profile assets, and generated reports.
- CloudFront for static web assets.
- AWS Load Balancer Controller for ingress.
- CloudWatch and OpenTelemetry for logs, metrics, and traces.
- AWS Secrets Manager for credentials.

## Immediate Next Code Tasks

1. Add a real chess rules package to Flutter and backend contract tests.
2. Add Stockfish engine adapter behind an interface.
3. Split Flutter UI into feature folders: game, coach, practice, profile, settings.
4. Add authentication module in backend.
5. Add OpenAPI specification and generated API client.
6. Add Terraform for AWS networking, EKS, RDS, Redis, and IAM.

