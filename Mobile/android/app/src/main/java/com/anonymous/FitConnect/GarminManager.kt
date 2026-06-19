package com.anonymous.FitConnect

import android.app.Activity
import android.content.Context
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.ConnectIQ.ConnectIQListener
import com.garmin.android.connectiq.ConnectIQ.IQApplicationEventListener
import com.garmin.android.connectiq.ConnectIQ.IQDeviceEventListener
import com.garmin.android.connectiq.ConnectIQ.IQMessageStatus
import com.garmin.android.connectiq.ConnectIQ.IQSdkErrorStatus
import com.garmin.android.connectiq.ConnectIQ.IQConnectType
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.exception.InvalidStateException
import com.garmin.android.connectiq.exception.ServiceUnavailableException

object GarminManager :
    ConnectIQListener,
    IQApplicationEventListener,
    IQDeviceEventListener {

    private const val WATCH_APP_UUID = "3051d135-d055-4657-8548-018c798198a5"

    // Important:
    // In TETHERED simulator mode, Garmin Android SDK may require empty app id.
    private const val SIMULATOR_APP_UUID = ""

    @Volatile
    var status: String = "GarminManager created"

    @Volatile
    var lastMessage: String = "No message yet"

    private var appContext: Context? = null
    private var connectIQ: ConnectIQ? = null
    private var selectedDevice: IQDevice? = null
    private var listenerRegistered = false

    private val simulatorApp = IQApp("")
    private val realWatchApp = IQApp(WATCH_APP_UUID)

    fun initialize(activity: Activity) {
        appContext = activity.applicationContext
        status = "Initializing SDK"

        connectIQ = ConnectIQ.getInstance(
            appContext,
            IQConnectType.TETHERED
        )

        try {
            connectIQ?.initialize(appContext, true, this)
            status = "SDK initialize called"
        } catch (e: Exception) {
            status = "SDK initialize exception"
            lastMessage = e.toString()
        }
    }

    override fun onSdkReady() {
        status = "SDK ready"
        refreshDevicesAndRegister()
    }

    override fun onInitializeError(error: IQSdkErrorStatus?) {
        status = "SDK init error: $error"
    }

    override fun onSdkShutDown() {
        status = "SDK shutdown"
        selectedDevice = null
        listenerRegistered = false
    }

    fun refreshDevicesAndRegister() {
        val ciq = connectIQ

        if (ciq == null) {
            status = "ConnectIQ is null"
            return
        }

        try {
            val knownDevices = ciq.knownDevices
            val connectedDevices = ciq.connectedDevices

            if (knownDevices.isEmpty()) {
                status = "No known Garmin devices"
                lastMessage = "Known=0, Connected=${connectedDevices.size}"
                return
            }

            val device = knownDevices[0]
            selectedDevice = device

            lastMessage =
                "Selected device:\n" +
                "Name: ${device.friendlyName}\n" +
                "Known count: ${knownDevices.size}\n" +
                "Connected count: ${connectedDevices.size}"

            registerDevice(device)

        } catch (e: InvalidStateException) {
            status = "Invalid state while reading devices"
            lastMessage = e.toString()
        } catch (e: ServiceUnavailableException) {
            status = "Garmin service unavailable"
            lastMessage = e.toString()
        } catch (e: Exception) {
            status = "Device refresh exception"
            lastMessage = e.toString()
        }
    }

    private fun registerDevice(device: IQDevice) {
        val ciq = connectIQ

        if (ciq == null) {
            status = "ConnectIQ is null during register"
            return
        }

        try {
            ciq.registerForDeviceEvents(device, this)
            status = "Device events registered: ${device.friendlyName}"
        } catch (e: Exception) {
            status = "Device event registration failed"
            lastMessage = e.toString()
            return
        }

        try {
            // For simulator/tethered mode.
            ciq.registerForAppEvents(device, simulatorApp, this)
            ciq.registerForAppEvents(device, realWatchApp, this)

            listenerRegistered = true
            status = "Both listeners registered"
            lastMessage =
                "Registered simulator app id: <empty>\n" +
                "Registered real app id: $WATCH_APP_UUID"
                
        } catch (e: Exception) {
            status = "Simulator app listener registration failed"
            lastMessage = e.toString()
        }
    }

    override fun onDeviceStatusChanged(
        device: IQDevice?,
        deviceStatus: IQDevice.IQDeviceStatus?
    ) {
        status = "Device status: ${device?.friendlyName} = $deviceStatus"

        if (device != null && !listenerRegistered) {
            selectedDevice = device
            registerDevice(device)
        }
    }

    override fun onMessageReceived(
        device: IQDevice?,
        app: IQApp?,
        message: MutableList<Any>?,
        messageStatus: IQMessageStatus?
    ) {
        status = "Message received: $messageStatus"

        if (message == null || message.isEmpty()) {
            lastMessage = "Empty message"
            return
        }

        lastMessage =
            "Device: ${device?.friendlyName}\n" +
            "App: $app\n" +
            "Status: $messageStatus\n" +
            "Message:\n" +
            message.joinToString(separator = "\n\n") { item ->
                item.toString()
            }
    }

    fun getDebugStatus(): String {
        return status
    }

    fun getDebugMessage(): String {
        return lastMessage
    }
}