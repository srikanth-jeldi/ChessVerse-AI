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
