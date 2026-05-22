import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

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
    namespace = "com.thomaspeterson.bikerouter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.thomaspeterson.bikerouter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // The Garmin Connect IQ Mobile SDK ships as an AAR. AGP 8 won't let a
    // Flutter plugin (library module) declare a direct local-AAR
    // implementation, so the host app pulls it in here while the plugin
    // depends on it compileOnly. Keeps a single source of truth in the
    // plugin tree.
    implementation(files("../../packages/garmin_connect/android/libs/ciq-companion-app-sdk-2.4.0.aar"))

    // Wearable Data Layer — sends turn-by-turn updates to a paired Wear OS
    // watch via DataClient / MessageClient (the Android side of v2.2).
    implementation("com.google.android.gms:play-services-wearable:18.2.0")
    // Provides Task.await() for the Wearable client calls in WatchBridge.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")
}
