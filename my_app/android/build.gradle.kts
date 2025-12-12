plugins {
    // The Android Gradle Plugin version.
    // The version here should match the one in your app's build.gradle.kts file.
    id("com.android.application") version "8.6.0" apply false
    // The Kotlin Gradle plugin version.
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    // The Google Services plugin, which processes google-services.json.
    id("com.google.gms.google-services") version "4.4.3" apply false
    // The Flutter Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// This section configures the build directory for the project.
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// Registers a task to clean the entire build directory.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
