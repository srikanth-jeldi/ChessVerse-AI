# ChessVerse OAuth Setup

Gmail SMTP credentials only send email OTPs. Google and Apple login use OAuth
credentials and must be verified by the ChessVerse backend before it creates a
session.

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

## Apple

1. Join the paid Apple Developer Program.
2. Register the ChessVerse App ID and enable the Sign in with Apple capability.
3. Add the capability to the iOS Runner target in Xcode.
4. For web and Android, create a Service ID. Configure the production domain
   and an HTTPS return URL such as
   `https://api.example.com/api/auth/apple/callback`.
5. Create a Sign in with Apple key and record the Team ID and Key ID. The `.p8`
   private key can only be downloaded once.
6. Store `APPLE_SERVICE_ID`, `APPLE_CLIENT_IDS`, `APPLE_TEAM_ID`, `APPLE_KEY_ID`,
   `APPLE_REDIRECT_URI`, and the `.p8` key in AWS Secrets Manager or an
   equivalent secret store. Never commit the key.
7. The Flutter client sends Apple's identity token to the backend. The backend
   validates its Apple signature, issuer, accepted audience and expiry, then
   issues a ChessVerse session. Authorization-code exchange and Apple refresh
   token revocation monitoring remain a production hardening milestone.

Apple web login requires a public HTTPS domain. Use a temporary HTTPS tunnel
for local callback testing; `localhost` is not a production return URL.

## Remaining Integration Inputs

Before provider buttons can be enabled, supply:

- Google Web client ID and server client ID
- Android package name and signing SHA-1 fingerprints
- iOS bundle identifier
- Apple Team ID, App ID, Service ID, Key ID, and private `.p8` key
- Final web domain and backend callback URL

Keep public client IDs in build configuration. Keep all private credentials in
local environment files, CI secrets, or AWS Secrets Manager.
