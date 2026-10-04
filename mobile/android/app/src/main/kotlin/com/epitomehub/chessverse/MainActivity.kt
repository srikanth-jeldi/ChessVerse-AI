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
        // Keep Flutter's faster default everywhere else and use TextureView only
        // for the affected Oppo Android 12/12L family.
        val isOppoAndroid12 =
            Build.VERSION.SDK_INT in Build.VERSION_CODES.S..Build.VERSION_CODES.S_V2 &&
                (Build.MANUFACTURER.equals("OPPO", ignoreCase = true) ||
                    Build.BRAND.equals("OPPO", ignoreCase = true))

        return if (isOppoAndroid12) RenderMode.texture else super.getRenderMode()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
