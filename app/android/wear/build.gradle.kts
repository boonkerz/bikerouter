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

// Load signing properties at file scope (same pattern as :app's
// build.gradle.kts). Reading inside the signingConfigs closure has
// caused subtle issues with Gradle's lazy evaluation order in this
// multi-module setup.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Helper: prefer property-file value, fall back to env var, treat
// empty strings as absent so a "keyPassword=" line doesn't override
// the env-var fallback with nothing.
fun signingValue(propKey: String, envKey: String): String? {
    val fromProps = keystoreProperties[propKey] as String?
    if (!fromProps.isNullOrEmpty()) return fromProps
    val fromEnv = System.getenv(envKey)
    if (!fromEnv.isNullOrEmpty()) return fromEnv
    return null
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

    // Reuse the phone app's release keystore. Both modules read the
    // same key.properties in android/, so the credentials stay in
    // sync. keyPassword falls back to storePassword when no
    // dedicated key password is supplied (common JKS convention).
    signingConfigs {
        create("release") {
            val storeFilePath = signingValue("storeFile", "CM_KEYSTORE_PATH")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                val storePw = signingValue("storePassword", "CM_KEYSTORE_PASSWORD")
                storePassword = storePw
                keyAlias = signingValue("keyAlias", "CM_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "CM_KEY_PASSWORD") ?: storePw
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
