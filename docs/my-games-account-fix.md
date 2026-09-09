# My Games account and pause correction

- Computer-game slot preparation and saving now include authenticated guest sessions. The server bearer identity owns the slot; it is not tied to the browser.
- Desktop and mobile Home actions explicitly await save before leaving. Both headers expose Pause and Save. Save failure keeps the board open with an error, rather than claiming success.
- Opening computer play with a saved slot offers Continue or New Game. Dismissing the choice changes nothing. New Game retains the existing revision-checked replacement behavior.
- Failed draft/completion writes are retryable: their success fingerprint is recorded only after the server acknowledges them.
- My Games uses server history only. It no longer merges or automatically imports device archives, whose account ownership cannot be verified.
- The old import endpoint returns 410 after authentication. Existing `legacy-` records are quarantined from history responses; records are not deleted or reassigned. Genuine older games in that category need separately verified ownership before restoration.
- Replay uses the same ChessBoard, 3D piece renderer, coordinates and move animation as gameplay, with correct white/black piece mapping.

An anonymous guest is a separate account. Cross-device recovery requires authenticating as the same account; creating another guest on a different device does not recover the previous guest's games.

This change needs both a backend and web/mobile update. It has not been deployed by this maintenance task.

## Verification

- 238 Flutter behavioral tests passed.
- All 20 gallery comparisons passed after refreshing only the two intentionally changed computer-game header snapshots. These use test fonts/placeholder assets and validate layout, not production image fidelity.
- 7 backend ComputerGameController tests passed.
- Flutter analysis: no issues found.
- Regression coverage includes guest mobile Pause, desktop Home save-before-exit, saved-position restoration, account slot isolation, no device-history import, and replay piece colours/move-animation inputs.
