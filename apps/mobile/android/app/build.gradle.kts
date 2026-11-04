import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Maps key and App Links host (S7 §4.9, §4.6): from android/secrets.properties (untracked) or the
// environment, so the key never enters the repository (SEC-004).
val secrets = Properties().apply {
    val f = rootProject.file("secrets.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun secret(name: String, default: String = "") = secrets.getProperty(name) ?: System.getenv(name) ?: default

android {
    namespace = "io.github.abdulbasitsaid.velio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.abdulbasitsaid.velio"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26 // Android 8 (MVP plan §10); Flutter needs 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["mapsApiKey"] = secret("MAPS_ANDROID_KEY")
        manifestPlaceholders["appLinksHost"] = secret("APP_LINKS_HOST", "depimls1pcvv4.cloudfront.net")
    }

    buildTypes {
        release {
            // Not distributed (S7 §12 Q2): the debug keystore signs every build, and its SHA-256 is the one
            // in the host's assetlinks.json.
            signingConfig = signingConfigs.getByName("debug")
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
