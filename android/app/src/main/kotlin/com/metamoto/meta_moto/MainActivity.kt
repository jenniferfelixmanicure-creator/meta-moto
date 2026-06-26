package com.metamoto.meta_moto

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
// import com.google.gson.Gson (removido para resolver erro de compilação)
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "com.metamoto.notifications/channel"
        const val EVENT_CHANNEL  = "com.metamoto.notifications/events"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── MethodChannel ─────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationListenerEnabled" ->
                        result.success(isNotificationListenerEnabled())

                    "openNotificationSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }

                    "hasOverlayPermission" ->
                        result.success(hasOverlayPermission())

                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        // ── EventChannel ──────────────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(RideEventStreamHandler)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun isNotificationListenerEnabled(): Boolean {
        val pkg = packageName
        val flat = Settings.Secure.getString(
            contentResolver, "enabled_notification_listeners") ?: return false
        return flat.split(":").any { it.contains(pkg) }
    }

    private fun hasOverlayPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }
}
