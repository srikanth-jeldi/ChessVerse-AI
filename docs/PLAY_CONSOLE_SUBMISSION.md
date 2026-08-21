# ChessVerseAI 1.0.0 — Play Console submission

## Release artifact

- Package: `com.epitomehub.chessverse`
- Version: `1.0.0` (`100`)
- App bundle: `artifacts/release-1.0.0/ChessVerseAI-1.0.0-100.aab`
- Privacy policy: `https://chessverseai.com/privacy`
- Terms: `https://chessverseai.com/terms`
- Data deletion: `https://chessverseai.com/data-deletion`
- Support email: `chessverseai@gmail.com`

## App content declarations

- App category: Game > Board
- Ads: No
- App access: Some functionality requires an account. Provide a dedicated test
  account to Play review; do not put a personal account in the instructions.
- Target audience: select only the age groups supported by the final content
  rating and privacy declarations. The current product is not designed as a
  child-directed app.
- News app: No
- Government app: No
- Financial features: None
- Health features: None
- Permissions: notifications and boot-completed only, in addition to internet.
  The app does not request microphone, camera, contacts, or broad storage.

## Data safety worksheet

Confirm each answer against the final Play Console wording before submission.

### Data collected

- Personal info: name/username, email address, profile image, country and player
  profile details. Purpose: account management, app functionality and social
  features.
- App activity: chess games, moves, ratings, puzzle/lesson progress,
  achievements, friends, clubs, tournaments and challenges. Purpose: gameplay,
  personalization, analytics within the product and fraud/anti-cheat protection.
- Messages: private chat text and user-selected chat attachments. Purpose: app
  functionality. These are not used for advertising.
- App info and performance: notification token, device/platform metadata,
  diagnostics and security signals. Purpose: notifications, reliability,
  security and fraud prevention.

### Handling declarations

- Data is encrypted in transit using HTTPS/TLS.
- Account holders can request deletion through the published data-deletion page.
- Chat attachments use the Android system picker; the app does not request broad
  storage access.
- Data is not sold and is not used for third-party advertising.
- Treat authentication/service providers strictly according to the Play Console
  definition of service providers when answering whether data is shared.

## Internal test gate

1. Create the app in Play Console and enable Play App Signing.
2. Complete Store listing, App content, Data safety and Content rating.
3. Upload the signed AAB to Internal testing.
4. Add at least two tester accounts and publish the internal test.
5. Install from the Play test link on two physical devices.
6. Verify login, friend request/accept, challenge accept/decline, same-room match,
   legal moves, clocks, reconnect and result.
7. Verify chat sent/delivered/seen, reply, emoji, image/file attachment and auto
   scroll.
8. Verify foreground, background and terminated-app notification tap routing.
9. Review pre-launch report, crashes/ANRs and automated device screenshots.
10. Promote only after every release gate passes.

## Required graphic assets

- App icon: 512 x 512 PNG, no transparency.
- Feature graphic: 1024 x 500 PNG/JPEG.
- Phone screenshots: at least 2; use the eight-screen production checklist in
  `docs/play-store-release-1.0.0.md`.
- Tablet screenshots: capture both 7-inch and 10-inch layouts.

Never include emails, OTPs, room codes, private messages, credentials or other
test-user personal data in store screenshots.
