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
2. Reads `flutter.sdk` and `sdk.dir` from `android\local.properties`.
3. **NDK check** — prints installed NDK revisions; downloads nothing. With
   `set INSTALLNDK=1` it installs `android-ndk-r27c` (rev `27.2.12479018`)
   from the first reachable mirror (Huawei → Tencent → Google) into
   `<sdk>\ndk\<revision>` using the `curl.exe`/`tar.exe` that ship with
   Windows 10/11 (resumable — re-run to continue a partial download).
4. Patches the **machine-local** Flutter SDK gradle build (root cause of the
   earlier `:gradle:compileKotlin` failures — section 6): `%FLUTTER_SDK%
   \packages\flutter_tools\gradle\settings.gradle.kts` (replaced, multi-mirror)
   and `build.gradle.kts` (repositories block appended). Originals saved as
   `*.arena.bak`.
5. `flutter pub get`
6. `flutter build appbundle --release` — 3 attempts: plain → purge possibly
   poisoned Gradle module-cache entries → plain again (transient mirror 502s).
7. `flutter build apk --release`
8. Prints artifact paths; on failure it probes every mirror for the **exact**
   failing artifacts and prints next-step guidance.

Optional flags: `set CLEANDEPS=1` (proactive cache purge), `set SKIPAPK=1`
(AAB only), `set INSTALLNDK=1` (install NDK, see section 5).

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
  (`appId 1:351828238865:android:acf438b940068f73d847b0`).
- SHA-1 registered in Firebase Console (done locally).
- `lib/firebase_options.dart` has **both `web` and `android`** options in
  FlutterFire format.
- `firebase login` only if you ever re-run `flutterfire configure`.

## 3) Keystore & key.properties (LOCAL ONLY — never committed)

```
android\upload-keystore.jks     ← keystore
android\key.properties          ← credentials (storePassword, keyPassword,
                                   keyAlias=upload, storeFile=upload-keystore.jks)
```

- `storeFile` resolves relative to `android/`.
- Release signs with the upload keystore when `key.properties` exists,
  otherwise falls back to the debug key (local testing only).
- **Back up the keystore + passwords** — losing them means a Play key reset.
  Verify SHA-1: `keytool -list -v -keystore android\upload-keystore.jks -alias upload`

## 4) Build commands (run on YOUR machine — sandbox has no Flutter/network)

Either the one-command script (section 0) or manually:

```
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

| Artifact | Path |
|----------|------|
| AAB (Play Store) | `build\app\outputs\bundle\release\app-release.aab` |
| APK (Bazaar)     | `build\app\outputs\flutter-apk\app-release.apk` |

**Play = AAB** · **Bazaar = APK**

## 5) NDK — why the build no longer demands one (or SDK Manager)

**History:** the old config had `ndkVersion = flutter.ndkVersion` (= `27.0.12077973`
on your SDK). If that NDK is not installed, AGP fails configuring `:app` with
*"NDK not configured. Download it with SDK manager. Preferred NDK version is
'27.0.12077973'"* and its auto-install fetches from dl.google.com (blocked for
you). The `android\build.gradle.kts line 27` in the error was just the
`evaluationDependsOn(":app")` line that surfaced it.

**Verified:** no file in flutter_tools injects `ndkVersion` — the only source
was that one line in `android/app/build.gradle.kts`. This app has no native
C/C++ sources; plugins ship prebuilt `.so` files, so an NDK is not required to
produce an AAB/APK.

**Now:** `android/app/build.gradle.kts` scans `<sdk>\ndk\*`:
- NDK installed → pins the best one (prefers `27.0.12077973`, else newest
  revision). No download, no SDK Manager.
- No NDK installed → sets nothing; the build proceeds without one.
- If you ever want an NDK without Android Studio:
  ```bat
  set INSTALLNDK=1
  tools\android_build_release.cmd
  ```
  Manual equivalent — zip URLs (first that works wins), extract so that
  `source.properties` sits **directly** in `<sdk>\ndk\<revision>\`:
  - `https://mirrors.huaweicloud.com/android/repository/android-ndk-r27c-windows.zip`
  - `https://mirrors.cloud.tencent.com/AndroidSDK/android-ndk-r27c-windows.zip`
  - `https://dl.google.com/android/repository/android-ndk-r27c-windows.zip`
  - release page: `https://github.com/android/ndk/releases/tag/r27c`
    (rev `27.2.12479018`, ≈840 MB for Windows)

## 6) Network root cause & fix (multi-mirror)

`android/settings.gradle.kts` declares
`includeBuild("$flutter.sdk/packages/flutter_tools/gradle")`. That included
build (`:gradle`) is a separate Gradle build with its **own** settings/build
files — it never sees the app's repositories, and Flutter ships it with
`FAIL_ON_PROJECT_REPOS` + `google()`/`mavenCentral()` only. On restricted
networks `:gradle:compileKotlin` died resolving AGP `8.11.1`,
`androidx.annotation:annotation-jvm:1.9.1`, `kotlin-gradle-plugin:2.0.0`.

**Fix shipped:** multi-mirror repositories (mirrors FIRST, originals as
fallback) in the app gradle files **and** a patch of the machine-local
flutter_tools gradle build (step 4 of the script; marker `ARENA-MIRRORS`;
undo via `*.arena.bak`). Plus 120 s HTTP timeouts in
`android/gradle.properties`.

Mirror order: Huawei → Tencent → repo1.maven.org → Aliyun
(public/google/central/gradle-plugin) → `google()` / `mavenCentral()` /
`gradlePluginPortal()`.

Version pins (evidence-based): AGP `8.11.1` (flutter_tools' compile target;
Gradle 9 supports AGP ≥ 8.4), KGP `2.3.20` (KGP 2.1.x caps at Gradle 8.10 —
breaks the cached 9.1.0 wrapper), google-services `4.3.15`, Gradle wrapper
`9.1.0` (already downloaded).

On failure the script prints an HTTP probe of the exact failing artifacts:
`HTTP 200` = mirror OK · `404` = wrong path · `000`/timeout = blocked. If ALL
time out: one hotspot/VPN run warms `%USERPROFILE%\.gradle\caches` and future
builds go from cache. Flutter packages already use the China mirrors
(`PUB_HOSTED_URL` / `FLUTTER_STORAGE_BASE_URL`).

## 7) What's left for you (user-only)

1. [ ] `tools\android_build_release.cmd`
2. [ ] Upload `app-release.aab` to **Google Play Console**.
3. [ ] Upload `app-release.apk` to **Cafe Bazaar** developer panel.
4. [ ] Back up `upload-keystore.jks` + `key.properties` + passwords (section 3).
5. [ ] `firebase login` only if you need the Firebase/FlutterFire CLI again.

No manual Gradle, NDK, or Firebase file edits are needed.

## 8) Versioning

Version lives in `pubspec.yaml` (`version: 1.0.0+1`). Bump the `+N` before
**every** store upload.
