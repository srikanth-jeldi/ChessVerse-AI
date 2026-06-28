# Online Multiplayer and Phone OTP

## Phone OTP

The backend supports:

- `POST /api/auth/register-phone`
- `POST /api/auth/verify-phone`
- password login using an E.164 phone number such as `+919876543210`

For production, use native Amazon SNS:

```text
SMS_MODE=sns
AWS_REGION=ap-south-1
```

The AWS SDK publishes a `Transactional` SMS directly to the E.164 phone number.
Locally it uses the AWS CLI credential profile. On EKS it uses Pod Identity and
the least-privilege `sns:Publish` role in
`infrastructure/aws/sns-pod-identity.yaml`; no long-lived AWS key is stored in
the application.

New AWS accounts start in the SNS SMS sandbox and can send only to verified
test numbers. India local-route production delivery also requires TRAI/DLT
registration, an approved sender ID, Entity ID and Template ID. Those values
map to `SMS_SENDER_ID`, `SMS_INDIA_ENTITY_ID`, and
`SMS_INDIA_TEMPLATE_ID`.

The generic HTTPS gateway mode remains available for a non-AWS provider:

```text
SMS_MODE=gateway
SMS_GATEWAY_URL=
SMS_GATEWAY_TOKEN=
```

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
