package com.anonymous.FitConnect

import com.facebook.react.bridge.*

class GarminModule(
    reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "GarminModule"

    @ReactMethod
    fun getLastMessage(promise: Promise) {
        promise.resolve(GarminManager.lastMessage)
    }

    @ReactMethod
    fun getStatus(promise: Promise) {
        promise.resolve(GarminManager.status)
    }

    @ReactMethod
    fun getConnectionSnapshot(promise: Promise) {
        val snapshot = Arguments.createMap().apply {
            putString("status", GarminManager.status)
            putString("message", GarminManager.lastMessage)
            putInt("receivedCount", GarminManager.receivedMessageCount)
            putDouble("lastReceivedAt", GarminManager.lastReceivedAt.toDouble())
            putBoolean("physicalDeviceMode", GarminManager.isPhysicalDeviceMode())
        }
        promise.resolve(snapshot)
    }

    @ReactMethod
    fun refreshConnection(promise: Promise) {
        GarminManager.refreshDevicesAndRegister()
        promise.resolve(GarminManager.getDebugStatus())
    }

    @ReactMethod
    fun sendPingToWatch(promise: Promise) {
        GarminManager.sendPingToWatch()
        promise.resolve(GarminManager.getDebugStatus())
    }
}
