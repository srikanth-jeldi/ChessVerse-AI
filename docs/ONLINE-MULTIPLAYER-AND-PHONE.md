# Online Multiplayer and Phone OTP

## Phone OTP

The backend supports:

- `POST /api/auth/register-phone`
- `POST /api/auth/verify-phone`
- password login using an E.164 phone number such as `+919876543210`

Configure an HTTPS SMS gateway with:

```text
SMS_GATEWAY_URL=
SMS_GATEWAY_TOKEN=
SMS_SENDER=ChessVerse
```

The gateway receives a bearer-authenticated JSON request containing `to`,
`from`, and `message`. In AWS, API Gateway plus Lambda can validate this request
and publish the message through SNS. Keep provider credentials in AWS Secrets
Manager, not in the Flutter build or Git.

## Worldwide Matchmaking

`Local 2P` is two people sharing one device. A worldwide `Online Match` needs a
server-authoritative realtime service:

1. Authenticated player joins a Redis-backed matchmaking queue.
2. Matchmaker pairs players by rating, time control, region, and wait time.
3. A game service creates the match and assigns colors.
4. Clients subscribe through a WebSocket/STOMP gateway.
5. The server validates every move, clock update, resignation, draw, reconnect,
   and result before broadcasting it.
6. PostgreSQL stores completed games and rating changes.

For Kubernetes, queue and game ownership cannot live only in application
memory. Use Redis for matchmaking/presence, PostgreSQL for durable games, and a
shared message broker or sticky game ownership for WebSocket fan-out.

The Flutter selector exposes `Online Match` as an explicit deployment milestone
without presenting local play as internet multiplayer.
