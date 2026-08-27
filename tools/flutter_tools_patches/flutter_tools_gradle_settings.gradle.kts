// PATCHED by wedding_time tools\android_build_release.cmd  (marker: ARENA-MIRRORS)
// Original Flutter-shipped file kept as settings.gradle.kts.arena.bak next to this one.
//
// Why: the flutter_tools gradle build is an *included build* (includeBuild from the
// app's settings.gradle.kts). It does NOT inherit the app's repositories. Flutter
// ships it with dependencyResolutionManagement = FAIL_ON_PROJECT_REPOS and only
// google() + mavenCentral() — on restricted networks (Iran etc.) that makes
// :gradle:compileKotlin fail resolving com.android.tools.build:gradle:8.11.1,
// androidx.annotation:annotation-jvm:1.9.1 and kotlin-gradle-plugin.
//
// Changes vs the shipped file:
//  * pluginManagement.repositories added (multi-mirror first) so plugin markers
//    (kotlin-dsl, kotlin("jvm")) resolve without plugins.gradle.org
//  * dependencyResolutionManagement: PREFER_PROJECT (NOT FAIL_ON_PROJECT_REPOS)
//    + multi-mirror repositories tried first, originals kept as fallback.
pluginManagement {
    repositories {
        // ARENA-MIRRORS-START
        maven("https://mirrors.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        maven("https://repo1.maven.org/maven2/")
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        gradlePluginPortal()
        // ARENA-MIRRORS-END
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        // ARENA-MIRRORS-START
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
        // ARENA-MIRRORS-END
    }
}
