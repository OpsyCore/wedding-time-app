# Android Release Guide

Everything config-related is already done in the repo. Your machine only holds
the secrets (keystore + `key.properties`) and runs the builds.

## 1) App identity — DONE ✅

| Item             | Value                              |
|------------------|------------------------------------|
| `applicationId`  | `wedding.time.app`                 |
| `namespace`      | `wedding.time.app`                 |
| `MainActivity`   | `wedding.time.app.MainActivity`    |
| Firebase project | `wedding-time-8240d`               |

`wedding.time.app` is the permanent unique store ID — never change it after
first publish.

## 2) Firebase — DONE ✅ (in repo)

- `android/app/google-services.json` contains the `wedding.time.app` client
  (`appId 1:351828238865:android:acf438b940068f73d847b0`); the old
  `com.example.wedding_time` entry is still listed — harmless, keep it.
- SHA-1 registered in Firebase Console (you did this locally).
- `lib/firebase_options.dart` now has **both `web` and `android`** options in
  FlutterFire format, so `DefaultFirebaseOptions.currentPlatform` works on
  Android and Web (no more `UnsupportedError` on Android).
- If you ever re-run `flutterfire configure`, keep the Firebase CLI logged in:
  `firebase login` (user-side step, only if CLI is needed).

## 3) Keystore & key.properties (LOCAL ONLY — never committed)

Files on your machine only (both git-ignored):

```
android\upload-keystore.jks     ← keystore
android\key.properties          ← credentials
```

`android/key.properties` must contain:

```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

- `storeFile` resolves relative to `android/`.
- Release builds sign with `upload-keystore.jks` when `key.properties` exists;
  otherwise release falls back to the debug key (local testing only).
- **Keystore backup (user-only step):** copy `upload-keystore.jks` +
  `key.properties` + the passwords to a safe place (e.g. password manager +
  cloud vault). If this keystore is lost, Play requires a key reset to update
  the app. Verify it matches Firebase:

```
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

## 4) Build commands (run on YOUR machine — sandbox has no Flutter/network)

```
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

Outputs:

| Artifact | Path |
|----------|------|
| AAB (Play Store) | `build\app\outputs\bundle\release\app-release.aab` |
| APK (Bazaar)     | `build\app\outputs\flutter-apk\app-release.apk` |

**Play = AAB** · **Bazaar = APK**

## 5) What's left for you (user-only)

1. [ ] `flutter build appbundle --release` → upload `app-release.aab` to
       **Google Play Console** (internal testing first is recommended).
2. [ ] `flutter build apk --release` → upload `app-release.apk` to
       **Cafe Bazaar** developer panel.
3. [ ] Back up `upload-keystore.jks` + `key.properties` + passwords (step 3).
4. [ ] `firebase login` only if you need the Firebase/FlutterFire CLI again.

No manual Gradle or Firebase file edits are needed — everything is committed.

## 6) Network problems ("Read timed out")

Already fixed in the repo — Aliyun mirrors are tried FIRST (before
Google/Maven Central/Gradle Plugin Portal) in `android/settings.gradle.kts`
and `android/build.gradle.kts`:

- `https://maven.aliyun.com/repository/google`
- `https://maven.aliyun.com/repository/central`
- `https://maven.aliyun.com/repository/gradle-plugin`
- `https://maven.aliyun.com/repository/public`

HTTP timeouts are 120 s (`android/gradle.properties`, 4 `systemProp.*` keys).
The Gradle 9.1.0 distribution is already cached on your PC.

If something still times out: re-run the build (Gradle resumes cached
downloads), or use a VPN/hotspot once to warm `%USERPROFILE%\.gradle\caches`.
Flutter packages: you already use the China mirrors —

```
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

## 7) Versioning

Version lives in `pubspec.yaml` (`version: 1.0.0+1` → versionName `1.0.0`,
versionCode `1`). Bump the `+N` before **every** store upload.
