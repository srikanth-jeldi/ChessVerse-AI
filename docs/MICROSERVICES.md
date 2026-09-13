# ChessVerseAI service decomposition

ChessVerseAI uses a strangler migration so the public mobile/web API remains
stable while the Spring Boot monolith is separated safely.

## Deployable roles

| Role | Ownership | Routed paths |
| --- | --- | --- |
| identity | accounts, sessions, cloud profile/progress | `/api/auth`, `/api/v1/progress`, `/api/v1/computer-game`, `/api/v1/ai-bot-presets` |
| play | games, realtime play, social, chat, tournaments, notifications | `/api/v1/games`, `/api/v1/online`, `/api/v1/leaderboard`, `/api/v1/social`, `/api/v1/community`, `/api/v1/notifications`, `/ws/matches` |
| learning | Stockfish, AI coach, game analysis, puzzle sprint | `/api/v1/engine`, `/api/v1/coach`, `/api/v1/analysis`, `/api/v1/puzzle-sprints` |
| economy | wallet, purchases, cosmetics, missions | `/api/v1/economy`, `/api/v1/purchases`, `/api/v1/shop`, `/api/v1/progression` |
| platform | contact and public health compatibility | `/api/contact`, `/api/v1/health` |

The legacy deployment remains available with `CHESSVERSE_SERVICE_ROLE=all`.
Each split instance returns 404 for endpoints it does not own. Nginx keeps one
stable public origin, including WebSocket upgrade forwarding.

## Local run

```text
docker compose -f docker-compose.microservices.yml up --build
```

The gateway is available on port 8080. Backend service ports are intentionally
not exposed to the host.

## Migration guarantees

- The public URLs and payloads do not change.
- Only the owning role runs analysis recovery, purchase reconciliation,
  tournament scheduling, disconnect monitoring, and attachment migration.
- Phase 1 retains one PostgreSQL database to avoid unsafe distributed
  transactions during rollout. Flyway serializes migrations.

## Next isolation phase

1. Replace direct auth package calls with signed access-token validation.
2. Replace play/progression calls to `EconomyService` with idempotent wallet
   commands and an outbox.
3. Give each service its own database/schema and Flyway history.
4. Extract role packages into independent Maven modules/images.
5. Add gateway contract tests, tracing, per-service dashboards, and canary
   rollout before removing the `all` role.
