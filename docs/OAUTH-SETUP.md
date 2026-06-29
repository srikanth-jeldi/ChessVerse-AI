# ChessVerse OAuth Setup

Gmail SMTP credentials only send email OTPs. Google login uses OAuth
credentials and must be verified by the ChessVerse backend before it creates
a session.

## Google

1. Create or select a project in Google Cloud Console.
2. Configure the OAuth consent screen, app name, support email, privacy policy,
   and the `email`, `profile`, and `openid` scopes.
3. Create these OAuth clients:
   - Web: add the production web origin and local development origin
     `http://localhost:53123`.
   - Android: register the Android package name plus release and debug SHA-1
     fingerprints.
   - iOS: register the iOS bundle identifier and URL scheme.
4. Set `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_SERVER_CLIENT_ID` in the Flutter
   build. Set `GOOGLE_CLIENT_IDS` on the backend to a comma-separated list of
   every accepted Web, Android, iOS and server client ID. Never put a client
   secret in the Flutter application.
5. The Flutter client uses `google_sign_in` and sends the Google identity token
   to the backend.
6. The backend verifies the token issuer, audience, signature, expiry, and
   nonce before finding or creating the ChessVerse account and issuing its own
   session token.

## Remaining Integration Inputs

Before provider buttons can be enabled, supply:

- Google Web client ID and server client ID
- Android package name and signing SHA-1 fingerprints
- iOS bundle identifier

Keep public client IDs in build configuration. Never commit OAuth client
secrets.
