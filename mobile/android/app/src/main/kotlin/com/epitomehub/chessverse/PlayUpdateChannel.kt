package com.epitomehub.chessverse

import android.content.Context
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

object PlayUpdateChannel {
    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(
            messenger,
            "com.epitomehub.chessverse/app_update",
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            if (call.method != "availableVersionCode") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            // Lazy, asynchronous Play query after Flutter has loaded. Never
            // wait for Binder/network work on the activity's main thread.
            try {
                AppUpdateManagerFactory.create(context).appUpdateInfo
                    .addOnSuccessListener { info ->
                        result.success(
                            if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE)
                                info.availableVersionCode() else null
                        )
                    }
                    .addOnFailureListener { result.success(null) }
            } catch (_: Exception) {
                // Offline, sideloaded and unsupported Play environments must
                // continue into the game without a fabricated update warning.
                result.success(null)
            }
        }
    }
}
