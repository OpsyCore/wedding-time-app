pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Multi-mirror FIRST (restricted-network friendly: Iran/China/carrier NAT).
        // Order matters — Gradle tries repositories in listed order; originals are
        // kept at the end as fallback. Requires the matching patch of the included
        // flutter_tools gradle build (tools/android_build_release.cmd does it).
        maven("https://mirrors.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        maven("https://repo1.maven.org/maven2/")
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.11.1 = the exact version flutter_tools is compiled against
    // (flutter.internal.agpVersion default in
    //  $flutter.sdk/packages/flutter_tools/gradle/build.gradle.kts).
    // Runs fine on the gradle-9.1.0 wrapper (Gradle 9 supports AGP >= 8.4).
    id("com.android.application") version "8.11.1" apply false
    // KGP 2.3.20 = what this project's Flutter SDK templates ("match SDK").
    // KGP 2.1.x is NOT an option: its max supported Gradle is 8.10, and this
    // project uses the cached gradle-9.1.0 wrapper (KGP 2.3.x supports 9.3).
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
}

include(":app")
