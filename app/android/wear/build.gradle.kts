// Wear OS companion app for Wegwiesel.
// Embedded into the Phone AAB via `wearApp(project(":wear"))` so it
// ships under the same Play Console listing and same applicationId
// as the Phone app. Play Store delivers this APK only to devices
// matching `android.hardware.type.watch`.

import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    // Renders Compose to PNG on the JVM for store screenshots (no emulator).
    id("app.cash.paparazzi")
}

// Load signing properties at file scope (same pattern as :app's
// build.gradle.kts).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(propKey: String, envKey: String): String? {
    val fromProps = keystoreProperties[propKey] as String?
    if (!fromProps.isNullOrEmpty()) return fromProps
    val fromEnv = System.getenv(envKey)
    if (!fromEnv.isNullOrEmpty()) return fromEnv
    return null
}

// Pull version from the Flutter pubspec so phone + wear APKs are
// always released together with the same version code. Avoids the
// "version code mismatch" rejection in Play Console.
fun pubspecVersion(): Pair<String, Int> {
    val pubspecFile = rootProject.file("../pubspec.yaml")
    val content = pubspecFile.readText()
    val match = Regex("""^version:\s*([0-9]+(?:\.[0-9]+)*)(?:\+([0-9]+))?""",
        RegexOption.MULTILINE).find(content)
    val versionName = match?.groupValues?.get(1) ?: "1.0.0"
    val versionCode = match?.groupValues?.get(2)?.toIntOrNull() ?: 1
    return versionName to versionCode
}

val (pubspecVersionName, pubspecVersionCode) = pubspecVersion()

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
        // Must match the phone module's applicationId. Play Store
        // delivers a single bundle and chooses the right APK based on
        // the device's <uses-feature> filters (watch hardware here).
        applicationId = "com.thomaspeterson.bikerouter"
        minSdk = 30
        targetSdk = 35
        versionCode = pubspecVersionCode
        versionName = pubspecVersionName
    }

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

    implementation("com.google.android.gms:play-services-wearable:18.2.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")

    // Paparazzi screenshot test (JVM, no emulator).
    testImplementation(composeBom)
    testImplementation("junit:junit:4.13.2")
}
