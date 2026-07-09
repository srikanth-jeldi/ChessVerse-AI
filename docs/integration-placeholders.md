# ChessVerse integration placeholders

This project is wired so the app can be built with dummy Google, Apple, Meta/Facebook, and VPS values during development. Replace only the values below when production credentials are ready.

## Flutter dart-defines

Use these names for web, Android, and iOS builds:

```powershell
flutter build apk `
  --dart-define=CHESSVERSE_ENV=staging `
  --dart-define=API_BASE_URL=https://api.chessverse.example `
  --dart-define=WEB_BASE_URL=https://play.chessverse.example `
  --dart-define=GOOGLE_WEB_CLIENT_ID=replace-google-web-client-id.apps.googleusercontent.com `
  --dart-define=GOOGLE_ANDROID_CLIENT_ID=replace-google-android-client-id.apps.googleusercontent.com `
  --dart-define=GOOGLE_IOS_CLIENT_ID=replace-google-ios-client-id.apps.googleusercontent.com `
  --dart-define=APPLE_SERVICE_ID=com.epitomehub.chessverse.signin `
  --dart-define=APPLE_REDIRECT_URI=https://api.chessverse.example/api/auth/apple/callback `
  --dart-define=FACEBOOK_APP_ID=replace-facebook-app-id `
  --dart-define=FACEBOOK_CLIENT_TOKEN=replace-facebook-client-token `
  --dart-define=PRIVACY_POLICY_URL=https://chessverse.example/privacy `
  --dart-define=TERMS_URL=https://chessverse.example/terms `
  --dart-define=DATA_DELETION_URL=https://chessverse.example/data-deletion
```

For release builds, `API_BASE_URL` must be HTTPS.

## Native replacement points

- Android package: `com.epitomehub.chessverse`
- Android placeholders: `mobile/android/app/src/main/res/values/strings.xml`
- iOS bundle config: `mobile/ios/Runner/Info.plist`
- Flutter config: `mobile/lib/core/config/app_config.dart`
- VPS env template: `infrastructure/vps/vps.env.example`
- Backend/app env template: `.env.example`

## What not to commit

Never commit real Gmail app passwords, database passwords, Facebook client tokens, Apple private keys, Google OAuth secrets, or VPS root credentials.

Use:

- local `.env` files on the server,
- GitHub Actions secrets,
- Hostinger/AWS environment variables,
- or manual `--dart-define` values for local release builds.

## Production checklist

1. Point `API_BASE_URL` to the live HTTPS API.
2. Add Google Web, Android, and iOS client IDs.
3. Add Apple Service ID and HTTPS callback URL.
4. Add Meta/Facebook App ID and Client Token in native config and dart-defines.
5. Configure backend OAuth callback endpoints for Google, Apple, and Facebook.
6. Configure SMTP with a verified sender.
7. Configure PostgreSQL/MySQL connection and run migrations.
8. Build APK/AAB/web with the same API domain.
