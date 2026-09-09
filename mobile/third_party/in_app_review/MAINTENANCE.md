# Local Android build compatibility patch

Source: pub.dev in_app_review 2.0.12 (MIT; see LICENSE).
All runtime Dart, Kotlin and Apple sources are unchanged.
Only android/build.gradle is migrated from the legacy Kotlin Android plugin
to AGP 9 built-in Kotlin, retaining Java/Kotlin target 11 and existing dependencies.
Requires Flutter 3.47.2+, AGP 9+, android.builtInKotlin=true.

Remove this local path dependency when an upstream release supports built-in
Kotlin. Validate requestReview/isAvailable/openStoreListing when replacing it.
