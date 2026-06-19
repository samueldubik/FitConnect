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
}