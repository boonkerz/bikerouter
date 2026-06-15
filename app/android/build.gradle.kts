// Paparazzi (alpha Compose-screenshot plugin) is only needed when generating
// Wear screenshots (-PwithPaparazzi, via scripts/wear-screenshots.sh). Adding it
// to the buildscript classpath solely under that flag keeps the flaky alpha
// plugin marker off normal release builds — resolving it during settings
// evaluation intermittently broke the Android release lane.
buildscript {
    if (gradle.startParameter.projectProperties.containsKey("withPaparazzi")) {
        repositories {
            google()
            mavenCentral()
            gradlePluginPortal()
        }
        dependencies {
            classpath("app.cash.paparazzi:paparazzi-gradle-plugin:2.0.0-alpha05")
        }
    }
}

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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
