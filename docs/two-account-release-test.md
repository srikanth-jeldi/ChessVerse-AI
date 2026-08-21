# Two-account release test

Use Account A on desktop/web and Account B on the latest Android APK.

1. A sends B a friend request; B receives it and accepts it; both friend lists update without refresh.
2. A challenges B; B can accept or decline. Decline notifies A. Accept opens the same server room/match for both players.
3. Verify colors are opposite, room/match identifiers agree, clocks stay within one second, and both clients receive every legal move.
4. Background one client briefly, return, and verify reconnect restores the same position and clock.
5. Exchange messages. Confirm single gray tick while sent, double gray on delivery, double cyan after the recipient opens the conversation.
6. Send a reply, emoji, image, and non-image file. Open/save the received attachments on both supported clients.
7. Mark all notifications read and confirm the badge clears immediately. Tap friend, challenge, accepted-match, message, and tournament notifications and confirm correct routing.
8. Finish by checkmate and resignation; verify both result dialogs, history, rating/stat updates, activity feed, and leaderboard eligibility.

Record the account names, device/browser versions, time, and any failure with screenshots or video. Do not approve Git/VPS production deployment until every step passes.
