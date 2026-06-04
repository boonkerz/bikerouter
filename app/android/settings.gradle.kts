pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
    // Compose Preview Screenshot Testing — renders @Preview composables to PNG
    // without an emulator (used by :wear for store screenshots). Version is
    // paired with AGP; bump if the first CI run reports an incompatibility.
    id("com.android.compose.screenshot") version "0.0.1-alpha10" apply false
}

include(":app")
// Wear OS companion (v2.2 phase 2). Standalone Wear OS 3+ app talking
// to the phone via the Wearable Data Layer.
include(":wear")
