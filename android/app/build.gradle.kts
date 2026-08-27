import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // AGP 8.11.x has no built-in Kotlin support — apply KGP explicitly
    // (version comes from android/settings.gradle.kts plugins block).
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Release signing reads android/key.properties (git-ignored, local machine only).
// Never commit key.properties or any .jks keystore — no real passwords in this repo.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// ---------------------------------------------------------------------------
// NDK: pin ONLY a version that actually exists on this machine.
//
// Detection lives in android/build.gradle.kts (runs before this file) and
// picks, in order: the ndk.dir NDK from local.properties, else the
// Flutter-preferred 27.0.12077973 if installed, else the newest revision under
// <sdk>\ndk\. When no NDK exists, nothing is pinned — this app has no native
// C/C++ sources and its plugins ship prebuilt .so files, so the NDK is not
// needed to produce an AAB/APK. This removes both failure modes:
//   * "NDK not configured. Download it with SDK manager" (missing pin target)
//   * "[CXX1104] NDK from ndk.dir ... disagrees with android.ndkVersion"
// To install an NDK without Android Studio / SDK Manager:
//   set INSTALLNDK=1 && tools\android_build_release.cmd
// Diagnose NDK state any time: tools\android_ndk_doctor.cmd
// ---------------------------------------------------------------------------
val pinnedNdk: String? =
    runCatching { rootProject.extra["ndkAlignedRevision"] as? String }.getOrNull()

if (pinnedNdk != null) {
    println("android/app: pinning installed NDK $pinnedNdk")
} else {
    println(
        "android/app: no installed NDK found — not pinning ndkVersion " +
            "(not needed for this app; install via tools\\android_build_release.cmd " +
            "with INSTALLNDK=1 if ever required)",
    )
}

android {
    namespace = "wedding.time.app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion intentionally NOT taken from flutter.ndkVersion unconditionally —
    // only pinned above when an installed NDK exists. No `ndk {}` block either:
    // no externalNativeBuild / NDK-consuming configuration anywhere in this app.

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "wedding.time.app"
        // Firebase Android SDKs in use (firebase_auth 5.x / cloud_firestore 5.x)
        // require at least API 23 — take the higher of Flutter's default and 23.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the upload keystore when key.properties exists (release builds),
            // otherwise fall back to the debug key so dev machines keep working.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
