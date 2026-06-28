# ChessVerse Apple OAuth Values

## App ID

- Description: `ChessVerse`
- Type: App
- Bundle ID: `com.epitomehub.chessverse`
- Bundle ID type: Explicit
- Capability: Sign in with Apple
- Primary App ID: Enable as primary

## Service ID

- Description: `ChessVerse Web`
- Identifier: `com.epitomehub.chessverse.web`
- Capability: Sign in with Apple
- Primary App ID: `com.epitomehub.chessverse`

Apple requires a public HTTPS domain before the Service ID can be completed.
Add the chosen domain under Domains and Subdomains and add its exact callback
under Return URLs.

Recommended production values after the domain is selected:

- Domain: `auth.<your-domain>`
- Return URL: `https://auth.<your-domain>/api/auth/apple/callback`

## Sign in with Apple Key

- Key name: `ChessVerse Sign in with Apple`
- Capability: Sign in with Apple
- Primary App ID: `com.epitomehub.chessverse`

Download the `.p8` file once and keep it outside Git. Record the Apple Team ID
and Key ID. Store the private key in AWS Secrets Manager for production.

## ChessVerse Runtime Configuration

```text
APPLE_SERVICE_ID=com.epitomehub.chessverse.web
APPLE_CLIENT_IDS=com.epitomehub.chessverse,com.epitomehub.chessverse.web
APPLE_REDIRECT_URI=https://auth.<your-domain>/api/auth/apple/callback
APPLE_TEAM_ID=<team-id>
APPLE_KEY_ID=<key-id>
```
