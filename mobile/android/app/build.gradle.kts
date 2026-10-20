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
// Opt-in side-by-side UI testing preserves the user's Play-signed installation.
val sideBySideUiTest = providers.gradleProperty("sideBySideUiTest")
    .orElse(providers.environmentVariable("CHESSVERSE_UI_TEST"))
    .map { it.toBoolean() }.orElse(false)
val admobAndroidAppId = providers.gradleProperty("ADMOB_ANDROID_APP_ID")
    .orElse(providers.environmentVariable("ADMOB_ANDROID_APP_ID"))
    .orElse("ca-app-pub-3940256099942544~3347511713")
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
        manifestPlaceholders["admobApplicationId"] = admobAndroidAppId.get()
        ndk {
            // Keep every advertised ABI complete. Some plugins ship x86_64
            // JNI libraries; omitting Flutter's matching engine/app binaries
            // still makes Play generate an x86_64 split that crashes at
            // startup when ReLinker falls back to an ARM64 libflutter.so.
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
        debug {
            if (sideBySideUiTest.get()) {
                applicationIdSuffix = ".uitest"
            }
        }
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
    implementation("com.google.android.play:app-update:2.1.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // google_mobile_ads pulls WorkManager transitively. Its legacy 2.7.0
    // runtime can fail while creating WorkDatabase on newer Android devices,
    // before Flutter is even started. Pin the newest line that still supports
    // this app's minSdk so AndroidX Startup uses the fixed implementation.
    implementation("androidx.work:work-runtime:2.9.1")

    // Google's 2.2.0 release fixes a crash in HsdpShimActivity. Keep this
    // explicit so older transitive ad dependencies cannot select 2.1.0.
    implementation("com.google.android.play:hsdp:2.2.0")

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
