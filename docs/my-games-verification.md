# My Games: account save and resume

## Behaviour

- Home → My Games exposes one unfinished computer game for the signed-in account.
- New Game asks before replacing an existing paused game. Completed history is separate.
- Returning from the computer board waits for a successful save. A failed save keeps the board open with a reconnect message.
- Position, move history, clocks, side, computer level, captured pieces and undo history are restored.
- Server revisions reject stale-device writes; opening the saved game on another device transfers write ownership.
- Completed computer games are archived separately. Existing retained device computer history is imported idempotently when My Games is opened.
- Account deletion cascades to the slot and computer history. Guest play does not claim a cross-device slot.
- No translation or other paid API is introduced. Cross-device sync requires connectivity to the existing backend.

## Automated verification

- Focused backend controller tests cover authentication, stale updates, stale completion, idempotent completion and preserving history when replacing a slot.
- Flutter tests cover single-slot replacement, account isolation, stale confirmation, stale saves, ordered writes, network errors and restoring the saved board.
- Emoji/clock layout regression test is retained.
- The five pre-existing game UI failures were resolved in maintenance release 1.2.38+158. Full Flutter suite including golden comparisons: 255 passed; see `build-maintenance-158.md`.

## Before release

- Deploy backend migration V51 before the updated client.
- Verify on two real signed-in devices: make moves, go back, open My Games and Continue on the second device; confirm board, side and clocks.
- Try simultaneous devices and confirm stale writes are rejected.
- Cancel replacement, then accept replacement; confirm completed history is retained.
- Turn off connectivity before going back and verify the warning; reconnect and retry.
- Check account A/B isolation and account deletion against the deployed database.

No production deployment or AAB is part of this local implementation verification.

## Release candidate 1.2.37+157

- Added a dedicated My Games entry below Play in the desktop sidebar. Mobile retains Home → My Games in the top-right toolbar.
- Disabled automatic idle suggestions for all Easy/Medium/Hard daily challenges and puzzles; normal game idle hints are retained.
- Release-focused Flutter suite: 15 tests passed. Scoped static analysis: no issues.
- Full backend `test package`: 109 tests, zero failures/errors, using Java 21 and a short workspace temporary directory on Windows.
- The controller uses Spring Boot's configured Jackson 3 mapper; full application-startup tests cover dependency injection compatibility.
- Production requires migration V51 and a backend rebuild before serving the new web/mobile client.
