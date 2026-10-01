import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // AGP 9 supplies built-in Kotlin; Flutter follows the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use {
        keystoreProperties.load(it)
    }
}

android {
    namespace = "com.epitomehub.chessverse"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.epitomehub.chessverse"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            // Keep every ABI served by Play aligned with a matching Flutter
            // engine. Some 64-bit-capable phones still run a 32-bit Android
            // userspace, while ChromeOS/emulators can run x86_64.
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Without key.properties Gradle produces an unsigned release artifact.
            // A Play Store build must use the private upload key configured locally
            // or by the release CI environment.
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // google_mobile_ads pulls WorkManager transitively. Its legacy 2.7.0
    // runtime can fail while creating WorkDatabase on newer Android devices,
    // before Flutter is even started. Pin the newest line that still supports
    // this app's minSdk so AndroidX Startup uses the fixed implementation.
    implementation("androidx.work:work-runtime:2.9.1")

    // Google Mobile Ads currently resolves HSDP 2.0.1, whose shim activity can
    // crash when Play launches it without targetPackageName. Keep the patched
    // Play library on the runtime classpath.
    implementation("com.google.android.play:hsdp:2.1.0")

    // Stay on Billing 8 for Flutter plugin compatibility while taking the
    // latest 8.x fixes for ProxyBillingActivity/PendingIntent handling.
    implementation("com.android.billingclient:billing:8.3.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
