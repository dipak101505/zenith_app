plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties()
val localPropertiesFile = File(rootProject.projectDir, "key.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.zenith.lms"
    compileSdk = 35 // Increased to 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.zenith.lms"
        minSdk = 23
        targetSdk = 35 // Increased to 35
        versionCode = 4
        versionName = "1.0.1"
    }

    signingConfigs {
        create("release") {
            if (localProperties.containsKey("storeFile")) {
                storeFile = file(localProperties.getProperty("storeFile"))
                storePassword = localProperties.getProperty("storePassword")
                keyAlias = localProperties.getProperty("keyAlias")
                keyPassword = localProperties.getProperty("keyPassword")
            } else {
                // Handle the case where storeFile is not in key.properties
                println("Warning: storeFile not found in key.properties. Using debug keystore.")
                storeFile = file("$rootDir/debug.keystore") // Use debug keystore or specify a default
                storePassword = "android"  // Default debug keystore password
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // ... other release configurations (e.g., minifyEnabled)
        }
    }
}

flutter {
    source = "../.."
}
