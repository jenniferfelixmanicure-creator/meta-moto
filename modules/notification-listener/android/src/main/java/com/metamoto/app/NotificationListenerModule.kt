package com.metamoto.app

import android.provider.Settings
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule

class NotificationListenerModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "RideNotificationListener"

    companion object {
        private var instance: NotificationListenerModule? = null

        fun sendRideDetected(platform: String, amount: Double, rawText: String) {
            instance?.let { mod ->
                if (!mod.reactContext.hasActiveReactInstance()) return
                val params = Arguments.createMap().apply {
                    putString("platform", platform)
                    putDouble("amount", amount)
                    putString("rawText", rawText)
                    putDouble("timestamp", System.currentTimeMillis().toDouble())
                }
                mod.reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                    .emit("onRideDetected", params)
            }
        }
    }

    override fun initialize() {
        super.initialize()
        instance = this
    }

    override fun invalidate() {
        super.invalidate()
        if (instance === this) instance = null
    }

    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}

    @ReactMethod
    fun isPermissionGranted(promise: Promise) {
        try {
            val enabled = Settings.Secure.getString(
                reactContext.contentResolver,
                "enabled_notification_listeners"
            ) ?: ""
            promise.resolve(enabled.contains(reactContext.packageName))
        } catch (e: Exception) {
            promise.resolve(false)
        }
    }

    @ReactMethod
    fun openPermissionSettings(promise: Promise) {
        try {
            val intent = android.content.Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            reactContext.startActivity(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }
}
