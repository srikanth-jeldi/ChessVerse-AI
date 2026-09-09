allprojects {
    repositories {
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

    // Gradle 9 cannot snapshot the AAR produced by the jni Flutter plugin on
    // Windows/OneDrive and fails while hashing an otherwise valid artifact.
    // This task is a packaging bridge, so disabling state tracking keeps the
    // build deterministic while still running the task on every release build.
    if (project.name == "jni") {
        tasks.matching { it.name == "bundleReleaseAar" }.configureEach {
            doNotTrackState("Gradle 9 cannot snapshot the generated JNI AAR on Windows")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Fail explicitly if a dependency reintroduces legacy Kotlin. This validates
// the applied plugins, not just declarations found by Flutter's source scanner.
val verifyBuiltInKotlin = tasks.register("verifyBuiltInKotlin") {
    doLast {
        check(providers.gradleProperty("android.builtInKotlin").orNull == "true") {
            "This project requires AGP built-in Kotlin and Flutter 3.47.2+."
        }
        val legacy = subprojects.filter {
            it.pluginManager.hasPlugin("org.jetbrains.kotlin.android") ||
                it.pluginManager.hasPlugin("kotlin-android")
        }.map { it.name }
        check(legacy.isEmpty()) { "Legacy Kotlin Android plugin applied by: $legacy" }
        logger.lifecycle("Verified built-in Kotlin: no legacy KGP applied.")
    }
}

subprojects {
    tasks.matching { it.name == "preBuild" }.configureEach {
        dependsOn(verifyBuiltInKotlin)
    }
}
