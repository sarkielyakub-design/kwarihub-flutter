import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ztechuniversalsolution.kwarihub"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ztechuniversalsolution.kwarihub"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val propertiesFile = rootProject.file("key.properties")

            if (!propertiesFile.exists()) {
                throw GradleException(
                    "Missing android/key.properties. Configure the upload key before building a release."
                )
            }

            val properties = Properties()
            propertiesFile.inputStream().use { stream ->
                properties.load(stream)
            }

            keyAlias = properties.getProperty("keyAlias")
                ?: throw GradleException("Missing keyAlias in key.properties")

            keyPassword = properties.getProperty("keyPassword")
                ?: throw GradleException("Missing keyPassword in key.properties")

            storePassword = properties.getProperty("storePassword")
                ?: throw GradleException("Missing storePassword in key.properties")

            val keystorePath = properties.getProperty("storeFile")
                ?: throw GradleException("Missing storeFile in key.properties")

            storeFile = file(keystorePath)

            if (!storeFile!!.exists()) {
                throw GradleException("Upload keystore file was not found: $keystorePath")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}