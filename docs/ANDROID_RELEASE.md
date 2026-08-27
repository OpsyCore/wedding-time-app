# Android Release Build Guide

Config is already set up in the repo — you only supply local secrets (keystore +
`key.properties`, never committed).

## 1) App identity

| Item            | Value              |
|-----------------|--------------------|
| `applicationId` | `wedding.time.app` |
| `namespace`     | `wedding.time.app` |
| `MainActivity`  | `wedding.time.app.MainActivity` |

The Play Store / Bazaar treat `wedding.time.app` as the permanent unique ID —
it must never change after first publish.

## 2) Keystore & key.properties (LOCAL ONLY — never committed)

Files live on your machine only (both are in `.gitignore`):

```
android/upload-keystore.jks     ← your keystore
android/key.properties          ← credentials (4 keys below)
```

`android/key.properties` must contain exactly these keys (real passwords go
here, never anywhere in git):

```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

Notes:
- `storeFile` is resolved **relative to the `android/` folder**, so
  `storeFile=upload-keystore.jks` points at `android/upload-keystore.jks`.
- `android/app/build.gradle.kts` reads this file automatically:
  release builds are signed with `upload-keystore.jks` when `key.properties`
  exists; if it doesn't, release falls back to the **debug** key (fine for
  local testing, NOT for store upload).

To verify the keystore and read its SHA-1:

```
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

## 3) Build commands

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

**Play = AAB** (`app-release.aab`).
**Bazaar = APK** (`app-release.apk`).

## 4) Network problems ("Read timed out")

Your original failure was network-only — Gradle couldn't reach
`plugins.gradle.org` for `kotlin-gradle-plugin` / the Flutter plugin loader.
The repo is already fixed for this:

- Aliyun mirrors are tried FIRST (before Google/Maven Central/Gradle Plugin
  Portal) in `android/settings.gradle.kts` and `android/build.gradle.kts`:
  - `https://maven.aliyun.com/repository/google`
  - `https://maven.aliyun.com/repository/central`
  - `https://maven.aliyun.com/repository/gradle-plugin`
  - `https://maven.aliyun.com/repository/public`
- HTTP timeouts raised to 120 s in `android/gradle.properties` (4 `systemProp.*` keys).

If a download still times out:

1. Just run the build again — Gradle resumes cached downloads.
2. Try a VPN or phone hotspot for one run to warm the cache
   (`%USERPROFILE%\.gradle\caches`), then future builds use mirrors offline-ish.
3. Make sure Flutter itself uses China mirrors (you already use `flutter-io.cn`):
   ```
   set PUB_HOSTED_URL=https://pub.flutter-io.cn
   set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   ```
4. First build after these changes downloads a lot — let it finish even if slow.

## 5) Firebase checklist (package `wedding.time.app` + SHA-1)

⚠️ **The current `android/app/google-services.json` still contains the OLD
package `com.example.wedding_time`.** Until you replace it (step 3 below),
`flutter build` fails with
`No matching client found for package name "wedding.time.app"` — that is
expected, the fix is in the Firebase console, not in code.

1. [ ] Firebase Console → project **wedding-time-8240d** → ⚙️ Project settings
       → **Your apps** → **Add app → Android**.
2. [ ] Package name: `wedding.time.app` (exactly), nickname optional → Register.
3. [ ] Download the new `google-services.json` and **replace**
       `android/app/google-services.json` with it.
4. [ ] Add SHA-1 (needed for Google Sign-In): click **Add fingerprint** on the
       new Android app and paste the SHA-1 from
       `keytool -list -v -keystore android\upload-keystore.jks -alias upload`
       (also add the `debug.keystore` SHA-1 if you test release flows from
       debug builds).
5. [ ] Regenerate Dart options:
       `dart pub global activate flutterfire_cli` then
       `flutterfire configure`
       — this rewrites `lib/firebase_options.dart`. **Required:** the current
       `firebase_options.dart` only contains **web** options, so on Android
       `Firebase.initializeApp` throws `UnsupportedError` at startup until it
       includes an `android` entry for `wedding.time.app`.
6. [ ] Google Sign-In on Android uses `wedding.time.app` + SHA-1 — after the
       fingerprint is added, re-download `google-services.json` once more
       (the console updates OAuth clients inside it).

Do **not** hand-edit `google-services.json` / invent values — always download
from the Firebase console.

## 6) Quick sanity checks

- `applicationId` = `wedding.time.app` in `android/app/build.gradle.kts`.
- `key.properties` + `upload-keystore.jks` exist locally, are git-ignored
  (`git status` must never show them).
- Version lives in `pubspec.yaml` (`version: 1.0.0+1` → versionName
  `1.0.0`, versionCode `1`). Bump `+N` before every store upload.
