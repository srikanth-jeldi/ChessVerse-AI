# Release 1.2.76 (196)

Requested scope: cinematic mobile/web loading screen, official king app icon,
image optimization, signed Android bundle, Git push, and VPS web deployment.
Academy backend, migrations, and academy domain routing are not in this release.

## Asset budget

| Runtime image | Before | After |
| --- | ---: | ---: |
| Cinematic background | 1,922,735 bytes | 147,702 bytes |
| Master games hall | 1,480,196 bytes | 38,360 bytes |
| App icon | 723,958 bytes | 50,076 bytes |

The decorative font is a Latin/punctuation subset of Cormorant Garamond,
instantiated at weight 500 and renamed ChessVerse Serif. The original font was
1,195,560 bytes; the bundled derivative is 306,020 bytes. Its OFL license is
included. Other app/localization fonts are unaffected.

## Verification and publishing

Flutter analysis and all 319 functional tests passed. Loading-screen layout checks passed at 390x844,
320x568, and 844x390; generated previews were visually reviewed.

The local Android build failed because Gradle could not establish a loopback
connection, including after an IPv4 retry. Therefore no new local signed AAB
or verified download size is claimed.

The production Android workflow now estimates the compressed initial download
using Google's bundletool 1.18.3 and rejects a maximum of 30,000,000 bytes or
more. The CSV is included with the signed AAB artifact. This is an estimate;
Play Console remains authoritative for actual served download sizes.

The VPS workflow accepts a web-only scope, preserves the old web image as
`chessverse-web:before-latest-web-release`, and updates web with `--no-deps`.
It does not restart backend/database in that scope. The frontend may reconnect
briefly while the web container is recreated.

Git push and production workflow execution require the explicit confirmation
requested after automatic approval review rejected the initial attempt.
