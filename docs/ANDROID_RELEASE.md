# Android Release Guide

Everything config-related is done in the repo. Your machine holds the secrets
(keystore + `key.properties`) and runs the builds — ideally with **one
command**: `tools\android_build_release.cmd`.

## 0) One-command build (recommended)

From the repo root:

```bat
tools\android_build_release.cmd
```

The script is idempotent and safe to re-run. It:

1. Renames `%USERPROFILE%\.gradle\init.gradle` → `init.gradle.bak` (user init
   scripts can force repository-mode settings that break Flutter builds).
2. Reads `flutter.sdk` from `android\local.properties` (falls back to
   `C:\src\flutter`).
3. Patches the **machine-local** Flutter SDK gradle build — this is the real
   root cause of your `:gradle:compileKotlin` failures (see section 6):
   `%FLUTTER_SDK%\packages\flutter_tools\gradle\settings.gradle.kts`
   (replaced, multi-mirror) and `build.gradle.kts` (repositories block
   appended). Originals are saved as `*.arena.bak` next to the files.
4. `flutter pub get`
5. `flutter build appbundle --release` — 3 attempts: plain →
   `--refresh-dependencies` (clears poisoned metadata cache) → plain again
   (transient 502s).
6. `flutter build apk --release`
7. Prints artifact paths; on failure it probes every mirror for the **exact**
   failing artifacts (AGP 8.11.1, annotation-jvm 1.9.1, kotlin-gradle-plugin
   2.0.0) and prints next-step guidance.

Optional flags (set before running): `set CLEANDEPS=1` (purge possibly
poisoned Gradle module-cache entries), `set SKIPAPK=1` (AAB only).

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
- SHA-1 registered in Firebase Console (done locally).
- `lib/firebase_options.dart` has **both `web` and `android`** options in
  FlutterFire format, so `DefaultFirebaseOptions.currentPlatform` works on
  Android and Web.
- `firebase login` is only needed if you ever re-run `flutterfire configure`.

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
- **Keystore backup (user-only):** copy `upload-keystore.jks` +
  `key.properties` + the passwords to a safe place. If the keystore is lost,
  Play requires a key reset to update the app. Verify:

```
keytool -list -v -keystore android\upload-keystore.jks -alias upload
```

## 4) Build commands (run on YOUR machine — sandbox has no Flutter/network)

Either the one-command script (section 0) or manually:

```
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

Outputs (the repo redirects the Android build dir to `<repo>\build`):

| Artifact | Path |
|----------|------|
| AAB (Play Store) | `build\app\outputs\bundle\release\app-release.aab` |
| APK (Bazaar)     | `build\app\outputs\flutter-apk\app-release.apk` |

**Play = AAB** · **Bazaar = APK**

## 5) Version decisions (evidence-based)

| Component | Version | Why |
|-----------|---------|-----|
| AGP (app) | `8.11.1` | The exact version flutter_tools compiles against (`flutter.internal.agpVersion` default in `$FLUTTER_SDK\packages\flutter_tools\gradle\build.gradle.kts`). Gradle 9.x supports AGP ≥ 8.4, so it runs on the cached gradle-9.1.0 wrapper. |
| KGP (app) | `2.3.20` | "Match SDK": this project's Flutter SDK templates KGP 2.3.20, which supports Gradle up to 9.3. KGP 2.1.x tops out at Gradle 8.10 — it would break on the 9.1.0 wrapper. |
| google-services | `4.3.15` | Battle-tested (was Flutter's own template pin through the AGP 8 era); resolves through the mirrors. If it ever errors at runtime, bump to 4.4.2/4.5.0 — the mirrors make those resolvable now. |
| Gradle wrapper | `9.1.0` | unchanged — already downloaded on your PC (~232 MB). |

## 6) Network root cause & fix

**Why app-side mirrors alone were not enough:** `android/settings.gradle.kts`
declares `includeBuild("$flutter.sdk/packages/flutter_tools/gradle")`. That
included build (`:gradle`) is a separate Gradle build with its **own**
`settings.gradle.kts` / `build.gradle.kts` — it never sees the app's mirrors.
Flutter ships it with `FAIL_ON_PROJECT_REPOS` and only `google()` +
`mavenCentral()`, so `:gradle:compileKotlin` tried dl.google.com /
repo.maven.apache.org directly and died on the restricted network
(`com.android.tools.build:gradle:8.11.1`,
`androidx.annotation:annotation-jvm:1.9.1`, `kotlin-gradle-plugin:2.0.0`).

**Fix shipped:**

- **Repo (git):** multi-mirror repositories (mirrors FIRST, originals as
  fallback) in `android/settings.gradle.kts` (pluginManagement) and
  `android/build.gradle.kts` (allprojects); 120 s HTTP timeouts in
  `android/gradle.properties`.
- **Machine-local (script):** rewrites
  `$FLUTTER_SDK\packages\flutter_tools\gradle\settings.gradle.kts` to
  `PREFER_PROJECT` + multi-mirror, and appends a multi-mirror `repositories {}`
  block to its `build.gradle.kts` (marker: `ARENA-MIRRORS`; undo via
  `*.arena.bak`).

Mirror order (both app and flutter_tools):

1. `https://mirrors.huaweicloud.com/repository/maven/`
2. `https://mirrors.cloud.tencent.com/nexus/repository/maven-public/`
3. `https://repo1.maven.org/maven2/`
4. `https://maven.aliyun.com/repository/public`
5. `https://maven.aliyun.com/repository/google`
6. `https://maven.aliyun.com/repository/central`
7. `https://maven.aliyun.com/repository/gradle-plugin`
8. then original `google()` / `mavenCentral()` / `gradlePluginPortal()`

If a build still fails, the script prints an HTTP probe of the exact failing
artifacts per mirror. Interpretation: `HTTP 200` = mirror OK; `404` = mirror
reachable but wrong path; `000`/timeout = mirror blocked. Gradle uses the
first mirror that answers, so at least one 200 is needed. Only if **all**
mirrors time out: run one build on a phone hotspot/VPN to warm
`%USERPROFILE%\.gradle\caches`, then future builds work from cache.

Flutter packages already use the China mirrors on your PC:

```
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

Note: `aar_init_script.gradle` in the SDK is only used by `flutter build aar`
(not by appbundle/apk) and is intentionally not patched.

## 7) What's left for you (user-only)

1. [ ] `tools\android_build_release.cmd` (or section 4 commands).
2. [ ] Upload `app-release.aab` to **Google Play Console**.
3. [ ] Upload `app-release.apk` to **Cafe Bazaar** developer panel.
4. [ ] Back up `upload-keystore.jks` + `key.properties` + passwords (section 3).
5. [ ] `firebase login` only if you need the Firebase/FlutterFire CLI again.

No manual Gradle or Firebase file edits are needed.

## 8) Versioning

Version lives in `pubspec.yaml` (`version: 1.0.0+1` → versionName `1.0.0`,
versionCode `1`). Bump the `+N` before **every** store upload.
