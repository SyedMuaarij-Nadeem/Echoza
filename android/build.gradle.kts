
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add the Google Services plugin classpath here
        classpath("com.google.gms:google-services:4.4.2") // Use the latest version
        // You might also have your Android Gradle Plugin here, e.g.:
        // classpath("com.android.tools.build:gradle:7.3.0")
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

