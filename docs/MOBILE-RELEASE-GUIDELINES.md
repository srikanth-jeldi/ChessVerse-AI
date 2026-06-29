# ChessVerse Mobile Release Guidelines

ChessVerse is an Android and iOS game. Flutter Web is a development and preview
target, not the primary product.

## Product Targets

1. Android phone and tablet
2. iPhone and iPad
3. Web/desktop preview after mobile quality gates pass

The game must remain usable offline for local two-player play. Online features,
account sync, cloud Stockfish, and multiplayer require the production API.

## Required Architecture

- `lib/core/`: configuration, networking, secure storage, logging, design system
- `lib/features/auth/`: registration, verification, session, profile
- `lib/features/game/`: board UI, game state, rules adapter, clocks, PGN
- `lib/features/engine/`: local/cloud Stockfish adapters and analysis
- `lib/features/multiplayer/`: matchmaking, game socket, presence, reconnect
- `lib/features/coach/`: move classification and teaching explanations

Widgets must not own backend sessions or implement chess rules. Use a proven
rules library, with the backend authoritative for online games.

## Security and Privacy

- Release APIs use HTTPS. Cleartext HTTP is permitted only in Android debug
  builds for local development.
- Store session tokens in Android Keystore and Apple Keychain, never plain
  preferences.
- Do not log passwords, OTPs, tokens, personal data, or payment information.
- Request only permissions used by an active feature.
- Provide account deletion, privacy policy, consent controls, and data-retention
  rules before launch.
- Keep signing material and production configuration outside Git.

## Android Release

1. Install the supported Flutter and Android SDK toolchains.
2. Generate a private Play upload key and store it outside the repository.
3. Copy `mobile/android/key.properties.example` to
   `mobile/android/key.properties` and supply real local values.
4. Build with the production HTTPS endpoint:

   ```powershell
   flutter build appbundle --release `
     --dart-define=API_BASE_URL=https://api.chessverse.example
   ```

5. Upload the AAB to an internal Play testing track first.
6. Complete physical-device tests, Play App Signing, Data Safety, content
   rating, screenshots, support details, and privacy-policy review.

An unsigned artifact or a build signed by a debug key is never a release.

## iOS Release

1. Build on macOS with the supported Xcode and Flutter toolchains.
2. Configure the Apple team, unique bundle identifier, signing certificate, and
   provisioning through Xcode.
3. Build with the production HTTPS endpoint:

   ```bash
   flutter build ipa --release \
     --dart-define=API_BASE_URL=https://api.chessverse.example
   ```

4. Distribute through TestFlight before App Store review.
5. Complete physical-device tests, privacy disclosures, age rating,
   screenshots, support details, and account-deletion review.

## Quality Gate

Every release candidate must pass:

- `flutter analyze` and `flutter test`
- Android debug and signed release compilation
- iOS archive compilation on macOS
- backend unit and integration tests
- rules tests for all standard endings and special moves
- airplane-mode, reconnect, background/resume, low-memory, and slow-network tests
- accessibility, localization, crash, performance, dependency, secret, and
  malware scans

## Current Blocking Work

- split the monolithic Flutter entry file into feature modules;
- replace handwritten rules with a proven chess rules package;
- persist and validate authenticated sessions;
- make backend game state authoritative;
- implement reconnect-safe multiplayer;
- add store-owned signing, observability, privacy, and release CI.
