# ChessVerse AI — Play Store release handoff

Release version: **0.1.5 (6)**
Package: **com.epitomehub.chessverse**
Track recommendation: **Internal testing**

## Signed artifacts

- Android App Bundle: `ChessVerse-AI-PlayStore-v0.1.5-build6.aab`
  - SHA-256: `E82C1729BC8085744B1F066B9806CFC981BD4F937F1F83989EA34DB5BA0214FD`
  - Upload-key certificate SHA-1: `30:AE:0E:06:B5:E6:4C:C1:32:62:25:01:2D:8F:92:F0:F2:BD:98:E6`
  - JAR signature: verified
  - Architectures: arm64-v8a, armeabi-v7a, x86_64
  - Native debug-symbol entries are embedded in the bundle metadata.
- Device-test APK: `ChessVerse-AI-Google-Profile-v0.1.5-build6-INSTALL.apk`
  - SHA-256: `0CF9347F5D9EFDD97DC4D9220EB90597ADFC5C005F00B3C1128F968DBA579A65`
  - APK Signature Schemes v2 and v3: verified

Never upload the APK in place of the AAB. Never share the upload keystore or
its password.

## Release notes

### English

Welcome to the new ChessVerse AI experience.

- Play live online matches with server-validated moves.
- Find rivals through random matchmaking or private rooms.
- Train in Puzzle Academy with Easy, Medium and Hard paths.
- Enjoy a redesigned premium game hub and player profile.
- Use Google Sign-In and see your Google profile photo in ChessVerse.
- Resume active online matches after reconnecting.
- Experience improved phone layouts, animations and gameplay feedback.

### Telugu

కొత్త ChessVerse AI అనుభవానికి స్వాగతం.

- Server-validated live online chess matches ఆడండి.
- Random matchmaking లేదా private room ద్వారా opponentsని కనుగొనండి.
- Easy, Medium, Hard Puzzle Academy training paths ప్రయత్నించండి.
- Premium game hub మరియు player profileని ఉపయోగించండి.
- Google Sign-Inతో మీ Google profile photoని ChessVerseలో చూడండి.
- Disconnect అయిన active online matchకి reconnect అవ్వండి.

## Play Console setup

1. Create/select app with package `com.epitomehub.chessverse`.
2. Enable Play App Signing.
3. Upload `ChessVerse-AI-PlayStore-v0.1.5-build6.aab` to Internal testing.
4. Confirm Play Console shows version name `0.1.5` and version code `6`.
5. Add internal testers and publish the internal-testing release.
6. Install only from the generated Play testing link.
7. Verify Google Sign-In. If Play App Signing uses a different app-signing
   certificate, add its SHA-1 to the Google Android OAuth credential.

## Required public URLs

- Website: https://chessverseai.com
- Privacy policy: https://chessverseai.com/privacy.html
- Terms: https://chessverseai.com/terms.html
- Account/data deletion: https://chessverseai.com/data-deletion.html
- Support email: chessverseai@gmail.com

## Data Safety draft

These answers are a submission draft and must be reviewed against the exact
Play Console wording before publishing.

### Data collected

- Personal information: name, email address, user ID.
- App activity: chess moves, match results, puzzle and progress activity.
- App information/performance: operational and security logs.
- Google Sign-In can provide account ID, display name, email and profile-photo
  URL. ChessVerse never receives the user's Google password.

### Purpose

- Account management and authentication.
- App functionality, multiplayer matchmaking, saved progress and game history.
- Fraud prevention, security and service reliability.

### Handling

- Data is encrypted in transit using HTTPS/WSS.
- Authentication tokens and the Google profile-photo URL are stored using
  platform secure storage on the device.
- Users can request account deletion through the published deletion page.
- The current release does not sell personal data.
- The current release does not use advertising SDKs.

## Internal-test acceptance checklist

- [ ] Install succeeds from the Play testing link.
- [ ] Google Sign-In completes and returns to the game hub.
- [ ] Google profile photo appears after a fresh Google login.
- [ ] Email/password login and logout work.
- [ ] Random online matchmaking pairs two distinct authenticated accounts.
- [ ] At least five legal moves synchronize on both devices.
- [ ] Background one device, reopen it and reconnect to the same match.
- [ ] Puzzle Academy opens independently from Daily Challenge.
- [ ] Profile username, country, level and avatar save without overflow.
- [ ] Portrait and landscape launch without clipped primary controls.

## Automated evidence

- Flutter focused regression suite: 8 tests passed.
- Backend online suite: 6 tests passed.
  - Random matchmaking pairs the second player.
  - Turn authority rejects an out-of-turn move.
  - Legal moves advance the authoritative turn.
  - Illegal chess moves are rejected.
  - Cancelling a waiting match removes it from reconnect.
  - WebSocket match updates broadcast to both players.
- Static analysis: no issues found.
- Production web markers and API health: verified.

## Known release limitations

- Play Console upload and Play-generated installation link require the owner's
  Play Console access and are not completed locally.
- Store screenshots, feature graphic and content-rating questionnaire still
  need approval/upload in Play Console.
- Physical two-device matchmaking, disconnect and reconnect evidence remains a
  release gate before promoting beyond Internal testing.
- The 150-puzzle catalog has 150 stable IDs, but a fully hand-curated set of
  150 individually authored and engine-certified positions remains future work.
