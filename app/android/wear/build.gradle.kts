// Wear OS companion app for Wegwiesel.
// Standalone (Wear OS 3+) — ships as its own APK alongside the phone app.

import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.thomaspeterson.bikerouter.wear"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    defaultConfig {
        applicationId = "com.thomaspeterson.bikerouter.wear"
        // Wear OS 3 lower bound — covers the vast majority of currently
        // active Wear devices and lets us ship Compose-for-Wear without
        // worrying about the legacy material library.
        minSdk = 30
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    // Reuse the phone app's release keystore. The properties file is in
    // the Android project root, alongside the phone module's gradle file.
    signingConfigs {
        create("release") {
            val props = Properties()
            val propFile = rootProject.file("key.properties")
            if (propFile.exists()) {
                props.load(FileInputStream(propFile))
            }
            val storeFilePath = props["storeFile"] as String?
                ?: System.getenv("CM_KEYSTORE_PATH")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = props["storePassword"] as String?
                    ?: System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = props["keyAlias"] as String?
                    ?: System.getenv("CM_KEY_ALIAS")
                keyPassword = props["keyPassword"] as String?
                    ?: System.getenv("CM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            val releaseConfig = signingConfigs.getByName("release")
            signingConfig = if (releaseConfig.storeFile != null) {
                releaseConfig
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

dependencies {
    // Compose-for-Wear keeps the UI a single-file affair; we don't need
    // the broader Material 3 stack because the watch glance is essentially
    // an icon + two text rows.
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)

    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")

    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")

    implementation("androidx.wear.compose:compose-foundation:1.4.0")
    implementation("androidx.wear.compose:compose-material:1.4.0")

    // Data Layer client — receives DataItem changes and Messages from the
    // phone-side WatchBridge.
    implementation("com.google.android.gms:play-services-wearable:18.2.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")
}
