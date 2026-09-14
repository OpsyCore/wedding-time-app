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
// Build Tools detection — same idea as the NDK above.
// AGP defaults to a Build Tools revision that may not be installed (35.0.0),
// and on networks where dl.google.com is unreachable it cannot download it
// ("Failed to find Build Tools revision 35.0.0"). So pick the newest
// revision that is actually present under <sdk>/build-tools.
// ============================================================================
fun buildToolsKey(v: String): List<Int> =
    v.split(".").map { it.toIntOrNull() ?: 0 }

val buildToolsInstalled: List<String> = ndkSdkDir
    ?.resolve("build-tools")
    ?.listFiles { f -> f.isDirectory }
    ?.map { it.name }
    .orEmpty()
    .filter { it.isNotEmpty() && it[0].isDigit() && !it.contains("-") }

val buildToolsChosen: String? = buildToolsInstalled.maxWithOrNull(
    compareBy(
        { v: String -> buildToolsKey(v).getOrNull(0) ?: 0 },
        { v: String -> buildToolsKey(v).getOrNull(1) ?: 0 },
        { v: String -> buildToolsKey(v).getOrNull(2) ?: 0 },
    ),
)

println(
    "root: build-tools installed=[" + buildToolsInstalled.joinToString(", ") +
        "] -> using '" + (buildToolsChosen ?: "<none>") + "'",
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

// Pin Build Tools as well — AGP would otherwise insist on its own default.
subprojects {
    val subproject = this
    val alignBuildTools: () -> Unit = {
        if (buildToolsChosen != null) {
            runCatching {
                val ext = subproject.extensions.findByName("android")
                ext?.javaClass?.methods?.firstOrNull {
                    it.name == "setBuildToolsVersion" && it.parameterCount == 1
                }?.invoke(ext, buildToolsChosen)
            }
        }
    }
    plugins.withId("com.android.library") { alignBuildTools() }
    plugins.withId("com.android.application") { alignBuildTools() }
    subproject.afterEvaluate { alignBuildTools() }
}

// ============================================================================
// SECOND pass — some plugin modules (notably ":jni") set android.ndkVersion
// in their OWN build.gradle, i.e. AFTER plugins.withId fires, which brings
// back [CXX1104] (ndk.dir=27.x vs android.ndkVersion=28.x).
// Re-assert the chosen revision once the module has finished evaluating so
// nothing can drift away from the installed NDK.
// ============================================================================
subprojects {
    val subproject = this
    subproject.afterEvaluate {
        if (ndkChosenRevision != null) {
            runCatching {
                val ext = subproject.extensions.findByName("android")
                val getter = ext?.javaClass?.methods?.firstOrNull {
                    it.name == "getNdkVersion" && it.parameterCount == 0
                }
                val setter = ext?.javaClass?.methods?.firstOrNull {
                    it.name == "setNdkVersion" && it.parameterCount == 1
                }
                val current = getter?.invoke(ext)?.toString()
                if (setter != null && current != ndkChosenRevision) {
                    setter.invoke(ext, ndkChosenRevision)
                    println(
                        "root: late-aligned '${subproject.path}' ndkVersion " +
                            "$current -> $ndkChosenRevision"
                    )
                }
            }
        }
    }
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