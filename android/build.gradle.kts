// ============================================================================
// NDK detection — runs FIRST, before any subproject evaluates.
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

val flutterPreferredNdk = "27.0.12077973"

val ndkChosenRevision: String? = ndkDirRevision
    ?: (if (flutterPreferredNdk in ndkInstalledRevisions) flutterPreferredNdk else null)
    ?: ndkInstalledRevisions.maxWithOrNull(
        compareBy(
            { it.split(".")[0].toIntOrNull() ?: 0 },
            { it.split(".")[1].toIntOrNull() ?: 0 },
            { it.split(".")[2].toIntOrNull() ?: 0 },
        ),
    )

extra["ndkChosenRevision"] = ndkChosenRevision
extra["ndkAlignedRevision"] = ndkChosenRevision
extra["ndkInstalledRevisions"] = ndkInstalledRevisions

println(
    "root: NDK installed=[" + ndkInstalledRevisions.joinToString(", ") + "]" +
        (ndkDirRevision?.let { " ndk.dir=$it" } ?: "") +
        " -> using '" + (ndkChosenRevision ?: "<none>") + "'",
)

// ============================================================================
// Mirrors for buildscript classpath (fixes plugins like audio_session that
// need com.android.tools.build:gradle:8.1.0 but google()/mavenCentral() are
// blocked on this network).
// ============================================================================
subprojects {
    buildscript {
        repositories {
            maven("https://maven.aliyun.com/repository/google")
            maven("https://maven.aliyun.com/repository/gradle-plugin")
            maven("https://maven.aliyun.com/repository/public")
            maven("https://mirrors.huaweicloud.com/repository/maven/")
            maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
            maven("https://plugins.gradle.org/m2/")
            google()
            mavenCentral()
        }
    }
}

// ============================================================================
// FORCE every Android module (app + every plugin library) onto the SAME
// installed NDK — via plugins.withId (fires immediately when the plugin is
// applied), NOT afterEvaluate. This is what actually fixes CXX1104 for
// modules like ":jni" that never set ndkVersion themselves and would
// otherwise fall back to AGP's built-in default (e.g. 28.2.13676358),
// which conflicts with ndk.dir.
// ============================================================================
subprojects {
    val subproject = this
    val alignNdk: () -> Unit = {
        if (ndkChosenRevision != null) {
            val ext = subproject.extensions.findByName("android")
            val setter = ext?.javaClass?.methods?.firstOrNull {
                it.name == "setNdkVersion" && it.parameterCount == 1
            }
            setter?.invoke(ext, ndkChosenRevision)
            println("root: aligned '${subproject.path}' ndkVersion -> $ndkChosenRevision")
        }
    }
    plugins.withId("com.android.library") { alignNdk() }
    plugins.withId("com.android.application") { alignNdk() }
}

// ============================================================================

allprojects {
    repositories {
        maven("https://maven.aliyun.com/repository/public")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://mirrors.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}