# Production authentication dependencies

The application code supports verified registration, login, session restore,
logout, verification-code resend, password reset, failed-login lockout and
single-instance API rate limiting.

The following external values are required before a production deployment can
be created:

- Cloud target and access credentials (AWS account/region, or an alternative).
- Managed PostgreSQL connection URL, username and password.
- API domain plus DNS control.
- TLS certificate ARN when using the supplied AWS ALB ingress.
- SMTP username, app password/API secret and verified `MAIL_FROM` address.
- Production web origin for CORS.
- Android upload keystore and Play Console access.
- Apple Developer Team, bundle identifier, signing certificates and a macOS
  Xcode build host for iOS.

Required backend environment variables are documented in `.env.example`.
Production must use the `prod` Spring profile and must never enable
`chessverse.auth.expose-development-code`.

The current rate limiter is process-local. Before running more than one backend
replica, replace it with a Redis-backed distributed limiter or route each client
consistently to a single replica.
