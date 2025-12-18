import org.gradle.api.tasks.Delete

// 1️⃣ Add plugin classpath
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0") // adjust if needed
        classpath("com.google.gms:google-services:4.3.15")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.10") // adjust Kotlin version
    }
}

// 2️⃣ Repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3️⃣ Custom build directory
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

// 4️⃣ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
