# Releasing Jerd

Jerd is distributed privately as an APK to a handful of shops, with an in-app
upgrade check instead of Play Store updates.

## 1. Identity and version

- Application id: `dz.jerd.app` (`android/app/build.gradle.kts`).
- Version: `version: x.y.z+build` in `pubspec.yaml`. Bump **build** on every
  release — the upgrade check compares build numbers.

## 2. Launcher icon

The icon is rendered by Flutter so the Arabic wordmark is shaped correctly:

```bash
flutter test tool/generate_icon_test.dart
dart run flutter_launcher_icons
```

## 3. Signing keystore (once)

```bash
keytool -genkey -v -keystore %USERPROFILE%\jerd-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias jerd
```

Create `android/key.properties` (git-ignored, never share it):

```properties
storePassword=...
keyPassword=...
keyAlias=jerd
storeFile=C:\\Users\\<you>\\jerd-release.jks
```

Losing the keystore means existing installs can never be updated — back it up.

## 4. Build

Obfuscated, with split debug info kept for Sentry symbolication:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/prod.json
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols --dart-define-from-file=config/prod.json
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk` and
`build/app/outputs/bundle/release/app-release.aab`.

## 5. Publish an upgrade

1. Upload the APK somewhere shops can download it (GitHub Releases works).
2. On Render set `LATEST_VERSION`, `LATEST_BUILD` (the new build number),
   `APK_URL` and `RELEASE_NOTES`.
3. To force everyone onto the new version (e.g. a sync format change), raise
   `MIN_BUILD` as well: older builds then show a non-dismissable update dialog.
4. Optionally announce it with a push to each shop's topic.
