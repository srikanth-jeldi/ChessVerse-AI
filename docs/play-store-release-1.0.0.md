# ChessVerseAI 1.0.0 Play Store release

## Release notes

Play smarter and improve every game with ChessVerseAI.

- Added reliable friend challenges and match-ready notifications.
- Added real chat sent, delivered, and seen status.
- Added image and file attachments in friend chat.
- Improved Community layouts across phones, tablets, and web.
- Improved notification navigation and unread badge updates.
- Improved online match synchronization and reconnect handling.
- Fixed responsive overflows and profile consistency issues.

## Store listing short release text

Smarter chess coaching, reliable online play, Community chat, challenges, puzzles, and learning—all in one premium chess experience.

## Screenshot checklist

Capture production data only; do not include email addresses, room codes, private chat, or test credentials.

1. Home — ChessVerseAI identity and Play Online hero.
2. Game board — live game with AI Coach.
3. AI Review — move classification and explanation.
4. Puzzle Academy — adaptive sprint and tactical levels.
5. Learn Chess — guided learning path.
6. Community Friends — friend challenge and active friends.
7. Community Clubs/Tournaments — premium cards and live counts.
8. Profile — rating, progress, badges, and activity.

Recommended phone assets: portrait PNG/JPEG, 1080×1920 or higher, no device frame. Also capture one 7-inch and one 10-inch tablet set.

## Privacy and permissions review

- Internet: required for accounts, online games, cloud progress, chat, and attachments.
- Notifications: required for friend requests, challenges, messages, tournaments, and personalized reminders; permission is requested at runtime.
- Boot completed: used only to restore scheduled local reminders after a device restart.
- No microphone permission.
- No camera permission.
- No contacts permission.
- No broad storage permission; attachments use the Android system picker.
- Chat attachments are limited to 10 MB and are available only to the authenticated sender and recipient.
- Calls are not included in this release.

Before production rollout, confirm the published privacy policy explicitly covers account data, chess activity, social data, notifications, and user-selected chat attachments, including deletion/support contact details.

## Final rollout gates

- Install the signed APK on two physical Android devices.
- Use two different accounts to verify friend request/accept, challenge accept/decline, both players entering the same match, moves, clocks, reconnect, and game result.
- Verify chat single tick, delivered double tick, seen blue double tick, reply, emoji, image attachment, file attachment, and automatic scroll.
- Verify foreground, background, and terminated-app notifications and tap routing.
- Verify phone, tablet, and web layouts at narrow, medium, and desktop widths.
- Upload the signed AAB to Play Console internal testing before production.
