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

    // Garmin's Android sample uses the manifest UUID as 32 hexadecimal
    // characters (without separators) for IQApp registration and messaging.
    private const val WATCH_APP_ID = "3051d135d05546578548018c798198a5"
    // A physical Android phone connected to the desktop watch simulator still
    // uses Garmin's ADB-backed TETHERED transport.
    private const val USE_TETHERED_SIMULATOR = true

    @Volatile
    var status: String = "GarminManager created"

    @Volatile
    var lastMessage: String = "No message yet"

    @Volatile
    var receivedMessageCount: Int = 0

    @Volatile
    var lastReceivedAt: Long = 0

    private var appContext: Context? = null
    private var connectIQ: ConnectIQ? = null
    private var selectedDevice: IQDevice? = null
    private var listenerRegistered = false

    private val connectType = if (USE_TETHERED_SIMULATOR) {
        IQConnectType.TETHERED
    } else {
        IQConnectType.WIRELESS
    }

    private val activeApp = IQApp(WATCH_APP_ID)

    fun initialize(activity: Activity) {
        appContext = activity.applicationContext
        status = "Initializing SDK"

        connectIQ = ConnectIQ.getInstance(
            appContext,
            connectType
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

            val device = connectedDevices.firstOrNull() ?: knownDevices[0]
            selectedDevice = device

            lastMessage =
                "Selected device:\n" +
                "Name: ${device.friendlyName}\n" +
                "Known count: ${knownDevices.size}\n" +
                "Connected count: ${connectedDevices.size}"

            registerDeviceEvents(device)

            if (connectedDevices.any { it.deviceIdentifier == device.deviceIdentifier }) {
                registerAppListeners(device)
            } else {
                listenerRegistered = false
                status = if (USE_TETHERED_SIMULATOR) {
                    "Waiting for simulator connection"
                } else {
                    "Waiting for Garmin watch connection"
                }
            }

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

    private fun registerDeviceEvents(device: IQDevice) {
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
    }

    private fun registerAppListeners(device: IQDevice) {
        val ciq = connectIQ

        if (ciq == null) {
            status = "ConnectIQ is null during app register"
            return
        }

        try {
            ciq.registerForAppEvents(device, activeApp, this)

            listenerRegistered = true
            status = if (USE_TETHERED_SIMULATOR) {
                "Simulator listener registered"
            } else {
                "Physical watch listener registered"
            }
            lastMessage = "Registered app id: ${activeApp.applicationId}"
                
        } catch (e: Exception) {
            status = "Garmin app listener registration failed"
            lastMessage = e.toString()
        }
    }

    override fun onDeviceStatusChanged(
        device: IQDevice?,
        deviceStatus: IQDevice.IQDeviceStatus?
    ) {
        status = "Device status: ${device?.friendlyName} = $deviceStatus"

        if (device != null && deviceStatus == IQDevice.IQDeviceStatus.CONNECTED) {
            selectedDevice = device
            registerAppListeners(device)
        } else if (deviceStatus != IQDevice.IQDeviceStatus.CONNECTED) {
            listenerRegistered = false
            selectedDevice = null
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

        receivedMessageCount += 1
        lastReceivedAt = System.currentTimeMillis()
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

    fun isPhysicalDeviceMode(): Boolean {
        return !USE_TETHERED_SIMULATOR
    }

    fun sendPingToWatch() {
        val ciq = connectIQ
        val device = selectedDevice

        if (ciq == null || device == null) {
            status = "Cannot send: ciq/device null"
            return
        }

        status = "Sending Android ping"

        try {
            ciq.sendMessage(device, activeApp, "hello from Android") { _, _, sendStatus ->
                status = "Android send status: $sendStatus"
                lastMessage = "Android → Watch ping attempted"
            }
        } catch (e: Exception) {
            status = "Android send exception"
            lastMessage = e.toString()
        }
    }
}
