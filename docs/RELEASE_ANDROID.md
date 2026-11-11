# Android release build (Google Play)

Reproducible steps for a signed Play upload (STORE-READY-001, 2026-11-11). Toolchain verified: Flutter 3.47.5, Dart 3.13.4, JDK 17, AGP 9.1.0, compile/target SDK 36, min SDK 24.

## One-time: upload key (owner only)
Release builds refuse to run without `android/key.properties`; there is no debug-signing fallback. Never commit the keystore or `key.properties` (both are git-ignored).

```bash
keytool -genkeypair -v -keystore ~/keys/nonogram-upload.jks -storetype PKCS12 \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

Keep the passwords in the team password manager and back the `.jks` up offline. Then create `android/key.properties`:

```properties
storePassword=<from password manager>
keyPassword=<from password manager>
keyAlias=upload
storeFile=/Users/<you>/keys/nonogram-upload.jks
```

On the first upload, enrol in Play App Signing (Google holds the app signing key; this key is only the upload key).

## Every release
1. Raise `version:` in `pubspec.yaml`; the build number after `+` must be higher than any earlier upload.
2. Resolve dependencies (the private SDK is only reachable over SSH on the build machine):
   ```bash
   GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=url.git@github-xbersoy:denogames/.insteadOf GIT_CONFIG_VALUE_0=https://github.com/denogames/ flutter pub get
   ```
3. Check and build. Pass no `--dart-define`: remote content is locked off in release builds anyway.
   ```bash
   flutter analyze && flutter test && flutter build appbundle --release
   ```
4. Verify the artifact `build/app/outputs/bundle/release/app-release.aab`:
   ```bash
   keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # must show the upload key, not "Android Debug"
   grep -o 'uses-permission[^>]*name="[^"]*"' build/app/intermediates/merged_manifest/release/*/AndroidManifest.xml
   ```
   Expected permissions: INTERNET only (plus the AndroidX-internal `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`). `BILLING` and `ACCESS_NETWORK_STATE` are removed in the main manifest while in-app purchases stay in mock mode; drop that removal when real purchases ship.
5. `git status` must be clean apart from ignored files before tagging or uploading.
