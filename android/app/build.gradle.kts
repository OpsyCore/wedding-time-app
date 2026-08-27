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
// NDK: pin ONLY a version that is already installed on this machine.
//
// Background: a pinned ndkVersion that is missing makes AGP fail configuring
// :app with "NDK not configured. Download it with SDK manager. Preferred NDK
// version is '27.0.12077973'" — and its auto-install downloads from
// dl.google.com (blocked on restricted networks). This app has no native
// C/C++ sources and its plugins ship prebuilt .so files, so nothing truly
// needs the NDK to produce an AAB/APK.
//
// Strategy:
//   * scan <sdk>\ndk\* (source.properties -> Pkg.Revision)
//   * prefer the Flutter-recommended 27.0.12077973, else the newest installed
//   * pin nothing when no NDK exists (build does not need it)
// To install an NDK without Android Studio / SDK Manager:
//   set INSTALLNDK=1 && tools\android_build_release.cmd
// (downloads from Huawei/Tencent mirrors into <sdk>\ndk\<revision>)
// ---------------------------------------------------------------------------
val sdkProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    FileInputStream(localPropertiesFile).use { sdkProperties.load(it) }
}

val androidSdkDir: File? = listOfNotNull(
    sdkProperties.getProperty("sdk.dir"),
    System.getenv("ANDROID_HOME"),
    System.getenv("ANDROID_SDK_ROOT"),
    System.getenv("LOCALAPPDATA")?.let { "$it\\Android\\Sdk" },
).firstOrNull { !it.isNullOrBlank() }?.let(::File)?.takeIf { it.isDirectory }

val installedNdkRevisions: List<String> = androidSdkDir
    ?.resolve("ndk")
    ?.listFiles { f -> f.isDirectory }
    ?.mapNotNull { dir ->
        runCatching {
            val props = Properties()
            val src = dir.resolve("source.properties")
            if (src.isFile) {
                FileInputStream(src).use { props.load(it) }
            }
            props.getProperty("Pkg.Revision")
        }.getOrNull()
    }
    ?.filterNotNull()
    .orEmpty()

val flutterPreferredNdk = "27.0.12077973" // matches flutter.ndkVersion of the pinned Flutter SDK
val pinnedNdk: String? = when {
    flutterPreferredNdk in installedNdkRevisions -> flutterPreferredNdk
    installedNdkRevisions.isNotEmpty() -> installedNdkRevisions.maxWith(
        compareBy(
            { it.split(".")[0].toIntOrNull() ?: 0 },
            { it.split(".")[1].toIntOrNull() ?: 0 },
            { it.split(".")[2].toIntOrNull() ?: 0 },
        ),
    )
    else -> null
}

if (pinnedNdk != null) {
    println("android/app: pinning installed NDK $pinnedNdk (found under ${androidSdkDir}\\ndk)")
} else {
    println(
        "android/app: no NDK installed under ${androidSdkDir ?: "<SDK>"}\\ndk — " +
            "not pinning ndkVersion (app builds fine without it; " +
            "install via tools\\android_build_release.cmd with INSTALLNDK=1 if ever needed)",
    )
}

android {
    namespace = "wedding.time.app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion intentionally NOT set from flutter.ndkVersion unconditionally —
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
