# ChessVerse AI

**Company:** EpitomeHub Technologies Pvt. Ltd.  
**Product Type:** AI-powered chess learning and gameplay platform  
**Status:** Sprint 1 engineering foundation started

ChessVerse AI is planned as a cross-platform chess product for Android, iOS and Web. The product goal is to combine chess gameplay, Stockfish-powered analysis, AI coaching, practice modes, multiplayer, learning paths, and enterprise-grade backend engineering into one professional product ecosystem.

## Product Vision

To build an intelligent chess platform where beginners can learn, intermediate players can improve, and advanced players can analyze their games with confidence.

## Core Capabilities

- Player vs Computer with levels 1–10
- Offline Player vs Player
- Online Multiplayer
- Stockfish engine integration
- AI move suggestions
- AI coach explanations
- Practice puzzles and training modes
- Game analysis and move history
- Ratings, leaderboards and tournaments
- Android, iOS and Web support
- CI/CD, cloud deployment and production monitoring

## Repository Structure

```text
docs/              Product documentation suite
backend/           Spring Boot backend services
mobile/            Flutter mobile application
web/               Future web application
infrastructure/    Docker, AWS, CI/CD and deployment assets
diagrams/          Architecture, database and flow diagrams
.github/           GitHub workflows and issue templates
```

## Current Implementation

- Spring Boot backend scaffold with game APIs, validation, persistence, Flyway migration and tests.
- Flutter app scaffold with responsive chess board, move history panel and AI action controls.
- Docker Compose for local PostgreSQL, Redis and backend runtime.
- Kubernetes manifests for backend deployment on AWS EKS.
- GitHub Actions CI for backend, mobile and backend container image builds.

## Quick Start

Backend tests:

```bash
cd backend
mvn test
```

Local backend stack:

```bash
copy .env.example .env
# Set a newly generated Gmail app password in .env.
docker compose up --build
```

SMTP credentials are loaded from `MAIL_USERNAME`, `MAIL_PASSWORD`, and
`MAIL_FROM`. Never commit `.env` or a real app password. Registration OTPs are
hashed, expire after ten minutes, allow five attempts, and are throttled to one
request per minute.

Local backend without Docker:

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

The local profile reads the ignored repository-root `.env` file automatically.

Flutter app:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Documentation Volumes

- Volume 01: Product Vision Document
- Volume 02: Business Requirements Document
- Volume 03: Software Requirements Specification
- Volume 04: High Level Design
- Volume 05: Low Level Design
- Volume 06: API Specification
- Volume 07: Database Design
- Volume 08: UI/UX Specification
- Volume 09: DevOps and CI/CD
- Volume 10: AWS Deployment
- Volume 11: Security Architecture
- Volume 12: Testing Strategy
- Volume 13: Operations Runbook

## Engineering Direction

Initial development will start as a modular monolith for speed, simplicity and maintainability. The architecture will be designed so that major domains can later be split into microservices when product scale demands it.

## Technology Direction

- Flutter
- Java 21
- Spring Boot
- Spring Security
- Spring AI
- PostgreSQL
- Redis
- WebSocket
- Stockfish
- Docker
- GitHub Actions
- AWS

## Current Phase

Sprint 1: Production codebase foundation, playable MVP architecture, CI/CD and cloud deployment baseline.

See [docs/PRODUCTION-ROADMAP.md](docs/PRODUCTION-ROADMAP.md) for the end-to-end production plan.
