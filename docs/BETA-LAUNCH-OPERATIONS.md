# ChessVerseAI beta launch operations

This is the no-cost operating plan for the first 20–50 external testers.

## Release gate

- Upload `mobile/build/app/outputs/bundle/release/app-release.aab` to the Google
  Play closed-testing track.
- Confirm the release shows version `1.2.5` and build `125` before rollout.
- Add tester email addresses through a Google Group so membership can be
  changed without editing each release.
- Keep the production rollout at 0% until the closed-test install link works.

## Tester invitation

Send testers the closed-test opt-in link with this message:

> ChessVerseAI beta is ready. Please install through this private Play link,
> play at least one AI game and one puzzle, then send feedback through the form.
> Do not share the private link or screenshots containing personal details.

Ask each tester to complete these checks:

1. Install or update the app.
2. Sign in with Google or create an account.
3. Start and finish an AI game.
4. Open a puzzle and a learning lesson.
5. Try an online match if another tester is available.
6. Close and reopen the app to verify session recovery.
7. Submit one feedback form, even when everything worked.

## Free feedback form

Create a Google Form named `ChessVerseAI Beta Feedback` with these fields:

- App version (short answer, required)
- Phone model and Android version (short answer, required)
- What were you trying to do? (paragraph, required)
- What happened? (paragraph, required)
- Severity (Works / Confusing / Blocks a feature / App crashed)
- Screenshot or screen recording (file upload, optional)
- May we contact you for follow-up? (Yes / No)
- Contact email (optional)

Do not request passwords, verification codes, access tokens, private chat text,
or government identifiers.

## Daily 15-minute review

1. Check Play Console Android vitals for crashes and ANRs.
2. Check Firebase Crashlytics for new fatal and non-fatal issues.
3. Check Firebase Analytics for `login_completed`,
   `guest_session_started`, and `game_started` events.
4. Check UptimeRobot and the production backup monitor.
5. Triage form responses: P0 crash/data loss, P1 blocked core flow, P2 confusing
   experience, P3 cosmetic suggestion.

## Funnel and launch threshold

Track only aggregate counts; never export user names or email addresses into the
funnel sheet.

| Funnel stage | Firebase signal | Beta target |
| --- | --- | --- |
| Installed/opened | automatic `first_open` | 20+ testers |
| Authenticated | `login_completed` or `guest_session_started` | 70% of opens |
| Started a game | `game_started` | 60% of authenticated users |
| Stable sessions | Crash-free users in Crashlytics | at least 99% |

Move from closed beta to a small production rollout only after three consecutive
days with no unresolved P0/P1 issue, crash-free users at or above 99%, successful
daily backups, and green uptime checks.
