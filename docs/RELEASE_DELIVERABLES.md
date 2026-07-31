# ChessVerse AI release deliverables

This checklist is the release gate for Android, web, and the future iOS build.
An item is complete only when the same Git commit is deployed to the VPS and
passes its listed acceptance checks.

## P0 — Account and release blockers

- [ ] Registration: create account, receive OTP, verify, sign in, and show the
      correct username/display name on home and profile.
- [ ] Password login: accept user ID or email and reject invalid credentials
      with a useful error.
- [ ] Forgot password: request reset code, set a new password, reject the old
      password, and accept the new password.
- [ ] Google sign-in: Android and web create/restore the same server-backed
      player with the correct name.
- [ ] Remember me: opted-in sessions survive backgrounding, orientation
      changes, app restart, and browser refresh; opted-out sessions do not.
- [ ] Logout: revoke the server session and return to login.
- [ ] SMTP: registration and reset emails deliver reliably without exposing
      credentials in logs or Git.
- [ ] Git/VPS parity: record and display the exact deployed Git SHA.
- [x] Signed Android artifacts: release APK for device testing and AAB for
      Play Console, both produced from the release commit.

## P0 — Chess correctness and stability

- [ ] Legal move enforcement, check, checkmate, stalemate, castling, en
      passant, promotion, repetition, 50-move rule, and insufficient material.
- [ ] Web and Android return the same result for the same position/move list.
- [ ] New game/replay fully resets turn, selection, overlays, clocks, AI state,
      coach state, and result state.
- [ ] Captured pieces disappear immediately for both player and opponent.
- [ ] No Flutter layout assertion, overflow stripe, frozen board, or stale
      piece after repeated moves.
- [ ] Portrait/landscape rotation is stable on Samsung F41, Samsung F14,
      tablet, and responsive web.

## P1 — Daily challenge

- [ ] Server/date-driven challenge changes every calendar day.
- [ ] Goal and move limit match the actual position and solution.
- [ ] Correct mate completes the challenge on Android and web.
- [ ] A missed challenge shows “Challenge missed” without a misleading 1–0
      score.
- [ ] Completion locks the challenge until the next daily reset and shows a
      live hours/minutes countdown.
- [ ] Challenge progress, streak, reward, and completion are server-backed and
      cannot be reset by reinstalling or clearing browser storage.

## P1 — Game experience and AI coach

- [ ] Home, Daily Challenge, Profile, Settings, and Logout are always reachable
      from the game screen in portrait, landscape, tablet, and web layouts.
- [ ] AI Coach explains “why this move” in plain language and references the
      correct side, piece, source square, destination square, threat, and plan.
- [ ] Hint, threat, evaluation, move history, captured pieces, and try-again
      controls show real game data.
- [ ] Move and capture animations finish without changing board geometry.
- [ ] Capture animation removes the victim at impact for both sides.
- [ ] Distinct audible cues for pawn, knight/horse neigh, bishop/elephant,
      rook, queen, king, capture, check, checkmate, win horn, loss, and draw.
- [ ] Sound on/off and volume settings persist.
- [ ] Existing 3D piece artwork is retained while the surrounding UI matches
      the approved premium coach layout.

## P1 — Online play

- [ ] Authenticated matchmaking and room creation/join flow.
- [ ] Authoritative server-side legal moves, clocks, reconnect, resign, draw,
      result, and anti-double-move handling.
- [ ] Opponent disconnect/reconnect UX and abandoned-game policy.
- [ ] Match history and rating updates.
- [ ] Basic abuse prevention, rate limits, and privacy-safe player identity.

## P2 — Product and store readiness

- [ ] Beautiful phone-specific splash plus tablet/web variants without crop.
- [ ] App icon, favicon, OAuth logo, and store branding are consistent.
- [ ] Privacy policy, terms, data deletion, support/contact, and account
      deletion are live and linked in-app.
- [ ] Play Store listing: title, descriptions, screenshots, feature graphic,
      privacy/data-safety forms, content rating, test track, and release notes.
- [ ] Crash/error monitoring, API health monitoring, database backups, restore
      test, log rotation, and uptime alerting.
- [ ] Accessibility: readable text scaling, contrast, semantic labels, touch
      targets, and keyboard navigation on web.
- [ ] Performance smoke tests on low/mid-range Android phones and major
      browsers.
- [ ] iOS signing, Sign in with Apple, App Store privacy metadata, screenshots,
      TestFlight, and review submission when a macOS/Xcode build environment is
      available.

## Release evidence required

- Git commit SHA and VPS deployed SHA.
- Passing backend auth/chess tests and Flutter analysis/tests.
- Signed APK, signed AAB, and production web URL.
- Device/browser test matrix with pass/fail evidence.
- Known limitations explicitly accepted before store submission.
