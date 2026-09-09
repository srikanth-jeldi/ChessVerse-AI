# Source-only Android build compatibility patches

Upstream packages and versions:

- firebase_core 4.14.0
- firebase_analytics 12.5.0
- firebase_crashlytics 5.3.0
- flutter_timezone 5.1.0
- in_app_review 2.0.12

Each directory retains its upstream LICENSE and runtime source. Sources came
from the matching pub.dev package archive already resolved by pub.

Changes are limited to Android Gradle configuration (remove legacy Kotlin
application/classpath and use built-in compiler options), removal of Firebase
`resolution: workspace` markers for local dependency resolution, and removal of
in_app_review's non-shipped screenshot metadata. No runtime source is modified.
Examples and screenshots are not shipped; supported platform implementation
directories are retained so web/Android/Apple/Windows builds keep working.

Flutter 3.47.2+ and AGP 9+ are required. `verifyBuiltInKotlin` in the Android
root build fails if any subproject actually applies legacy KGP.

Replace local paths with upstream releases when those releases remove legacy
KGP declarations. Retest Firebase startup/analytics/crash reporting, timezones,
store review requests, and the full application suite after replacement.
