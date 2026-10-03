# Android display and R8 validation

The production and preview entry points explicitly select Flutter's
`SystemUiMode.edgeToEdge`. The Android activity is resizable and neither the
manifest nor Dart startup restricts orientation. Game content respects all four
safe-area insets while its background continues behind the system bars. The
tablet header uses available layout width, and the coach progress label can wrap.

R8 full mode is enabled alongside existing code and resource shrinking. Existing
app keep rules and dependency consumer rules remain in effect.

## Automated checks

From `mobile`, run:

```powershell
flutter analyze --no-pub
flutter test --no-pub test/android_window_layout_test.dart test/widget_test.dart test/orientation_ui_audit_test.dart test/academy_responsive_test.dart test/auth_layout_regression_test.dart test/loading_screen_layout_test.dart
```

The window regression test keeps one game mounted while moving between portrait,
both landscape cutout arrangements, tablet widths, and a split-screen-sized
window. It checks that the board and back control stay within system insets and
that layouts do not overflow.

## Device and release checks still required

Build using the production bundle command in
`.github/workflows/android-production-release.yml`, then test the optimized
release through an internal track on Android 14, 15, and 16:

- Check gesture and three-button navigation, status-bar legibility, and display
  cutouts on both sides in landscape.
- Rotate during a local game and an online game; resize tablet split-screen
  windows. Verify board taps, clocks, coach controls, and retained game state.
- Open login and chat keyboards; verify focused fields and submit controls remain
  visible. Check sheets, dialogs, and bottom navigation near system bars.
- Smoke-test sign-in, notifications, purchases, test ads, and TTS in the optimized
  release to exercise plugin reflection paths affected by R8.

The local release build attempt on 2026-09-28 stopped before compilation with
`java.io.IOException: Unable to establish loopback connection`, caused by
`UnixDomainSockets.connect` reporting `Invalid argument: connect`. No new release
bundle or on-device R8 validation was produced by that attempt.

On Windows, Java's Unix-domain sockets use a separate temporary-directory
setting. The subsequent build passed the startup failure with this process-local
setting before the production Flutter build command:

```powershell
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=E:\ChessVerse-AI\.build-tmp'
```

The subsequent production build succeeded with R8 full mode. The upload bundle
is `releases/android-1.3.1-226-20260928-160312/ChessVerseAI-1.3.1-226.aab`.
Its signature and bundle structure were verified with jarsigner and bundletool.
The bundled manifest confirms version 1.3.1 (226), target SDK 36, a resizable
MainActivity, and no orientation restriction. Matching Dart symbols and R8
mapping are saved alongside it. Automated validation passed 68 tests and static
analysis; on-device runtime validation remains pending.
Bundletool estimates a maximum Play download of 28,223,928 bytes (28.22 MB),
within the release workflow's 30 MB budget. The generated size-check APK set is
debug-signed for estimation only; upload the separately verified release AAB.

## Historical ANR report

The reported build 224 (1.2.99) incident occurred on a Tecno POVA 7 5G running
Android 16. Play Console labels the captured main thread idle and explicitly
states that the stack does not show the problem. Its frames include ART
`ConditionVariable::WaitHoldingLocks`, display-vsync dispatch, and
`MessageQueue.nativePollOnce`. This is insufficient to attribute the ANR to a
specific app operation or to claim that the display/R8 changes fix it.

The existing app already defers several startup services until after the first
frame and initializes the ads SDK on demand. Validate cold starts, background /
resume, and rotation on the affected device with the new release. If the ANR
recurs, collect all thread stacks and a startup/system trace; do not classify it
as a vendor-only issue from this main-thread snapshot.

The additional pasted thread inventory includes Firebase, ads/WebView, Flutter,
and GPU workers, but only names and states, without their expanded stacks.
Waiting/timed-waiting workers alone do not demonstrate lock contention, a
deadlock, or an SDK-specific cause.

A later attachment supplied expanded stacks (1,454 lines), superseding that
inventory-only limitation. Both Flutter raster threads are in
`ALooper_pollOnce` / `fml::MessageLoopAndroid::Run`; Android's RenderThread is
also polling. Inspected Firebase and ads workers are waiting for queued work.
Impeller fence-worker stacks show condition-variable waits, not proof of a GPU
hang. The main-thread snapshot still does not identify the earlier no-focused-
window timeout's cause. This report is sufficient for initial stack triage;
additional copies of the same snapshot will not establish a causal fix.

### Review scrolling regression (version 228)

The mobile AI review sheet now respects top/side system insets and reserves the
bottom navigation inset. Move details and Previous/Next actions share one scroll
view so short landscape windows can reach every action. Long Telugu move-effect
labels wrap within their cards.

The regression test reproduced a summary action extending 32 pixels into the
bottom unsafe region before the fix. Swipe-based tests now verify summary,
Simple/Advanced review, and Previous/Next actions at 390x844, 360x640, and 844x390
with system insets, in English and Telugu. These six cases and the existing
review localization, review quality, and Android resize tests pass (10 tests).
Physical-device validation is still required; widget tests do not reproduce
Android input dispatch or establish that the historical ANR is resolved.

References: [Flutter edge-to-edge migration](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge)
and [Android R8 full mode](https://developer.android.com/topic/performance/app-optimization/full-mode).
