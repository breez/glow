import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties from key.properties file if it exists
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.breez.spark.glow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.breez.spark.glow"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            val debugStoreFile = keystoreProperties.getProperty("storeFileDebug")
            if (debugStoreFile != null) {
                keyAlias = keystoreProperties.getProperty("keyAliasDebug")
                keyPassword = keystoreProperties.getProperty("keyPasswordDebug")
                storeFile = file(debugStoreFile)
                storePassword = keystoreProperties.getProperty("storePasswordDebug")
            }
        }

        create("release") {
            val releaseStoreFile = keystoreProperties.getProperty("storeFile")
            if (releaseStoreFile != null) {
                // Use key.properties file
                println("Using key properties from key.properties file")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(releaseStoreFile)
                storePassword = keystoreProperties.getProperty("storePassword")
            } else {
                // Fall back to environment variables (for CI)
                val envStoreFile = System.getenv("STORE_FILE")
                if (envStoreFile != null) {
                    println("Using key properties from environment variables")
                    keyAlias = System.getenv("KEY_ALIAS")
                    keyPassword = System.getenv("KEY_PASSWORD")
                    storeFile = file(envStoreFile)
                    storePassword = System.getenv("STORE_PASSWORD")
                } else {
                    println("No storeFile provided, release builds will use debug keystore")
                }
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-debug"
            resValue("string", "app_name", "Glow - Debug")
        }
        release {
            signingConfig = signingConfigs.getByName("release")
            resValue("string", "app_name", "Glow")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}