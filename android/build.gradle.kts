// ============================================================================
// NDK detection & alignment — runs FIRST, before any subproject evaluates.
//
// Fixes [CXX1104] "NDK from ndk.dir ... had version [x] which disagrees with
// android.ndkVersion [y]" on machines where more than one NDK exists or where
// Flutter plugins pin flutter.ndkVersion (e.g. 27.0.12077973) without that
// exact revision being installed.
//
// Choice priority (first match wins):
//   1. the NDK pointed to by ndk.dir in android/local.properties (explicit
//      user choice — highest priority, per docs/ANDROID_RELEASE.md)
//   2. the Flutter-preferred revision (27.0.12077973) IF it is installed
//   3. the newest revision installed under <sdk>\ndk\
//   4. nothing (no NDK installed — this app builds fine without one; plugins
//      ship prebuilt .so files)
//
// The chosen revision is shared with android/app/build.gradle.kts via a root
// extra, and :app pins exactly that revision.
// ============================================================================
import java.io.FileInputStream
import java.util.Properties

val ndkLocalProperties = Properties()
val ndkLocalPropertiesFile = file("local.properties")
if (ndkLocalPropertiesFile.exists()) {
    FileInputStream(ndkLocalPropertiesFile).use { ndkLocalProperties.load(it) }
}

fun ndkRevisionOf(dir: File): String? =
    runCatching {
        val source = dir.resolve("source.properties")
        if (dir.isDirectory && source.isFile) {
            val props = Properties()
            FileInputStream(source).use { props.load(it) }
            props.getProperty("Pkg.Revision")
        } else {
            null
        }
    }.getOrNull()

val ndkSdkDir: File? = listOfNotNull(
    ndkLocalProperties.getProperty("sdk.dir"),
    System.getenv("ANDROID_HOME"),
    System.getenv("ANDROID_SDK_ROOT"),
    System.getenv("LOCALAPPDATA")?.let { "$it\\Android\\Sdk" },
).firstOrNull { !it.isNullOrBlank() }?.let(::File)?.takeIf { it.isDirectory }

val ndkInstalledRevisions: List<String> = ndkSdkDir
    ?.resolve("ndk")
    ?.listFiles { f -> f.isDirectory }
    ?.mapNotNull { ndkRevisionOf(it) }
    .orEmpty()

val ndkDirRevision: String? =
    ndkLocalProperties.getProperty("ndk.dir")?.let { ndkRevisionOf(File(it)) }

val flutterPreferredNdk = "27.0.12077973" // flutter.ndkVersion of the pinned Flutter SDK

val ndkAlignedRevision: String? = ndkDirRevision
    ?: (if (flutterPreferredNdk in ndkInstalledRevisions) flutterPreferredNdk else null)
    ?: ndkInstalledRevisions.maxWithOrNull(
        compareBy(
            { it.split(".")[0].toIntOrNull() ?: 0 },
            { it.split(".")[1].toIntOrNull() ?: 0 },
            { it.split(".")[2].toIntOrNull() ?: 0 },
        ),
    )

extra["ndkAlignedRevision"] = ndkAlignedRevision
extra["ndkInstalledRevisions"] = ndkInstalledRevisions

println(
    "root: NDK installed=[" + ndkInstalledRevisions.joinToString(", ") + "]" +
        (ndkDirRevision?.let { " ndk.dir=$it" } ?: "") +
        " -> using '" + (ndkAlignedRevision ?: "<none - build proceeds without NDK>") + "'",
)

// ============================================================================

allprojects {
    repositories {
        // Multi-mirror FIRST (restricted-network friendly); originals kept at the
        // end as fallback. Order matters — Gradle tries repositories in order.
        maven("https://mirrors.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        maven("https://repo1.maven.org/maven2/")
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// NOTE: do NOT register subproject afterEvaluate hooks in this file.
// The evaluationDependsOn(":app") above forces :app to evaluate DURING root
// evaluation, so any `subprojects { afterEvaluate { ... } }` registered after
// it throws "Cannot run Project.afterEvaluate(Action) when the project is
// already evaluated." NDK alignment is also unnecessary: the NDK choice is
// made once above (ndk.dir > 27.0.12077973-if-installed > newest installed),
// :app pins exactly that, and plugins pin flutter.ndkVersion — which equals
// the Flutter-preferred revision, so all pins agree as long as the preferred
// (or only) installed NDK is 27.0.12077973. Diagnose any mismatch with
// tools\android_ndk_doctor.cmd.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
