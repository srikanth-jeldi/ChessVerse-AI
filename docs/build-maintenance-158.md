# Build maintenance: 1.2.38+158

## Toolchain

- Flutter 3.47.2 / Dart 3.13.2, pinned in CI and the VPS web build.
- AGP 9.0.1 built-in Kotlin enabled; compiler classpath pinned to 2.3.20 without
  applying legacy KGP. Keep android.newDsl=false: this is a separate Flutter
  compatibility setting, not the Kotlin opt-out.
- The original developer SDK was not overwritten. Local verification uses
  `.build-tmp/flutter-3.47.2` (an official tagged checkout).

## Fixes

- Widget tests now mock saved preferences and await language initialization.
  The production language-loading guard is preserved, preventing English flashes.
- Position analysis asserts the current AI Coach sheet and its actual metrics.
- Settings values have bounded trailing width; section headings wrap at small
  widths and increased text scale.
- File picker call sites use the current single-file and byte-read APIs.
- Reminder timezone initialization uses the typed IANA identifier API.
- New Dart lint migrations are mechanical; unused profile header plumbing removed.

## Dependency patches

`mobile/third_party` retains source-only upstream plugin distributions and their
licenses. Android Gradle scripts are migrated to built-in Kotlin; Firebase pubspec
workspace markers are removed for standalone path resolution. Runtime Dart,
Kotlin, Swift, Objective-C and C++ source must remain identical to upstream.

Firebase and timezone upstream scripts retain old KGP fallback declarations even
on the migrated path. Flutter's source-based migration check flags those dormant
branches. The local patches remove the branches rather than hiding the warning.
Replace these patches with upstream packages when they no longer declare KGP.

## Verified tests

- Full Flutter suite, including Windows golden comparisons: **255 passed**.
- First-party Dart analysis (`dart analyze lib test`): **No issues found**.
- Final root-level `flutter analyze --no-pub`: **No issues found**.
- Compared **107 runtime source files** in the local plugin copies against the
  upstream packages: identical after newline normalization.
- Golden images retain Flutter's deterministic test font and are layout snapshots,
  not production-font screenshots. Updated Home, game, analysis, profile, settings,
  puzzles and saved-game layouts were inspected; a separate unmodified comparison
  run passed. Linux CI keeps behavioral tests separate from Windows pixel baselines.
- Added tests for 320/390/844-wide Settings at 1.3 text scale and Asia/Kolkata
  reminder timezone initialization.

- Signed release AAB built successfully (1.2.38+158); signer matches release 157.
- `verifyBuiltInKotlin`: **BUILD SUCCESSFUL**, no legacy KGP applied.
- The release-build log contains no Kotlin migration warnings.
- Generic upstream Gradle 10 deprecation advisories are separate from the Kotlin
  migration and remain visible; no warning-suppression flags were added.

Artifact checksum is recorded with the release artifact. Upstream source
whitespace is intentionally retained in the vendored copies.
