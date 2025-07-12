plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {

    flavorDimensions.add("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Persist Mail (DEV)")
        }
        create("alpha") {
            dimension = "flavor-type"
            versionNameSuffix = "-alpha"
            resValue("string", "app_name", "Persist Mail (ALPHA)")
        }
    }

    namespace = "site.persist.persist_mail_ui"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "site.persist.persist_mail_ui"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            applicationIdSuffix = ".debug"
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
