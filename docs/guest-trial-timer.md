# Guest trial timer

- AI Review and Mistake Bank each have two uses per local calendar day.
- Choosing Not now after exhaustion writes a per-identity, per-feature later_clicked_timestamp to secure storage.
- That feature remains locked for exactly ten days, overriding daily resets. Repeated visits show a localized snackbar with a Login now button, not the modal; visits never extend the deadline.
- At expiry, a fresh two-use quota opens. Signed-in users bypass the guest quota.
- Closing the dialog with Back/outside does not count as choosing Not now.
- Existing v1 lifetime counts are replaced by a fresh v2 daily quota on upgrade.
- Local-only enforcement is not tamper-proof; changing device time or clearing installation storage can affect it.

Validation: guest_conversion_test.dart covers concurrent quota consumption, persistence, daily reset, cooldown boundary, independent feature/account counters, idempotent account merge without coin copy, and 34-language narrow-screen layouts at 1.4 text scale. No physical-device test or release AAB was produced for this change.
