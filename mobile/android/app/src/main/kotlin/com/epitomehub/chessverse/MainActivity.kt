package com.epitomehub.chessverse

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ttsSettingsChannel = "com.epitomehub.chessverse/tts_settings"

    override fun getRenderMode(): RenderMode {
        // ColorOS 12 can block the UI thread while FlutterSurfaceView attaches
        // its SurfaceHolder, producing an ANR in FlutterJNI.nativeSurfaceCreated.
        // The same driver-level stall has been observed on Itel Android 14
        // devices. Keep Flutter's faster default everywhere else and use a
        // TextureView only for the affected OEM / OS combinations.
        val isOppoAndroid12 =
            Build.VERSION.SDK_INT in Build.VERSION_CODES.S..Build.VERSION_CODES.S_V2 &&
                (Build.MANUFACTURER.equals("OPPO", ignoreCase = true) ||
                    Build.BRAND.equals("OPPO", ignoreCase = true))
        val isItelAndroid14 =
            Build.VERSION.SDK_INT == Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                (Build.MANUFACTURER.equals("ITEL", ignoreCase = true) ||
                    Build.BRAND.equals("ITEL", ignoreCase = true))
        // Crashlytics also captures nativeSurfaceCreated lock contention on
        // X6531B / Android 14. Limit this mitigation to the observed model;
        // physical-device verification is still required.
        val isInfinixX6531BAndroid14 =
            Build.VERSION.SDK_INT == Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
                Build.MODEL.equals("Infinix X6531B", ignoreCase = true)
        val isXiaomiAndroid16OrNewer =
            Build.VERSION.SDK_INT >= 36 &&
                (Build.MANUFACTURER.equals("XIAOMI", ignoreCase = true) ||
                    Build.BRAND.equals("XIAOMI", ignoreCase = true) ||
                    Build.BRAND.equals("REDMI", ignoreCase = true) ||
                    Build.BRAND.equals("POCO", ignoreCase = true))

        return if (isOppoAndroid12 || isItelAndroid14 ||
            isInfinixX6531BAndroid14 || isXiaomiAndroid16OrNewer) {
            RenderMode.texture
        } else {
            super.getRenderMode()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Suppress ad traffic in automated testing, without changing gameplay.
        // Firebase documents this flag for Test Lab and Play pre-launch tests.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.epitomehub.chessverse/ad_environment")
            .setMethodCallHandler { call, result ->
                if (call.method != "suppressAds") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val testLab = Settings.System.getString(contentResolver, "firebase.test.lab") == "true"
                    val emulator = Build.HARDWARE == "goldfish" ||
                        Build.HARDWARE == "ranchu" ||
                        Build.PRODUCT.startsWith("sdk_gphone") ||
                        Build.PRODUCT.startsWith("sdk_google_phone")
                    result.success(testLab || emulator)
                } catch (_: Exception) {
                    result.error("AD_ENVIRONMENT_UNAVAILABLE", "Unable to check ad test environment", null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ttsSettingsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "installVoiceData") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                openTtsVoiceInstaller()
                result.success(null)
            }
    }

    private fun openTtsVoiceInstaller() {
        try {
            startActivity(Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA))
        } catch (_: ActivityNotFoundException) {
            try {
                startActivity(Intent("com.android.settings.TTS_SETTINGS"))
            } catch (_: ActivityNotFoundException) {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            }
        }
    }
}
