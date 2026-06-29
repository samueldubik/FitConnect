import Foundation
import ConnectIQ

final class GarminManager: NSObject, IQDeviceEventDelegate, IQAppMessageDelegate, IQUIOverrideDelegate {
    static let shared = GarminManager()

    private static let watchAppUUIDString = "3051d135-d055-4657-8548-018c798198a5"
    private static let returnURLScheme = "fitconnect"

    private var selectedDevice: IQDevice?
    private var activeApp: IQApp?
    private var listenerRegistered = false
    private var deviceReadyForCommunication = false

    private var ciq: ConnectIQ? {
        ConnectIQ.sharedInstance()
    }

    private(set) var status = "GarminManager created"
    private(set) var lastMessage = "No message yet"
    private(set) var receivedMessageCount = 0
    private(set) var lastReceivedAt: Int64 = 0

    private override init() {
        super.init()
    }

    func initialize() {
        guard let ciq else {
            status = "ConnectIQ singleton unavailable"
            return
        }

        ciq.initialize(
            withUrlScheme: Self.returnURLScheme,
            uiOverrideDelegate: self
        )

        status = "ConnectIQ initialized"
        lastMessage = "URL scheme: \(Self.returnURLScheme)"
    }

    func refreshDevicesAndRegister() {
        guard let selectedDevice else {
            requestDeviceSelection()
            return
        }

        registerDeviceEvents(for: selectedDevice)
    }

    func requestDeviceSelection() {
        guard let ciq else {
            status = "ConnectIQ singleton unavailable"
            return
        }

        status = "Opening Garmin device selection"
        ciq.showDeviceSelection()
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme == Self.returnURLScheme else {
            return false
        }

        guard
            let ciq,
            let devices = ciq.parseDeviceSelectionResponse(from: url) as? [IQDevice],
            let device = devices.first
        else {
            status = "No Garmin devices returned"
            lastMessage = "Garmin Connect returned no compatible devices"
            return false
        }

        clearConnectionState(status: "Garmin device selected")

        selectedDevice = device
        lastMessage = """
        Selected device:
        Name: \(device.friendlyName ?? "Unknown")
        Model: \(device.modelName ?? "Unknown")
        Devices returned: \(devices.count)
        """

        registerDeviceEvents(for: device)
        return true
    }

    private func registerDeviceEvents(for device: IQDevice) {
        guard let ciq else {
            status = "ConnectIQ unavailable during device registration"
            return
        }

        ciq.unregister(forDeviceEvents: device, delegate: self)
        ciq.register(forDeviceEvents: device, delegate: self)

        selectedDevice = device

        let currentStatus = ciq.getDeviceStatus(device)

        status = "Device events registered; checking watch app"
        lastMessage = """
        Device: \(device.friendlyName ?? "Unknown")
        Current device status: \(currentStatus.rawValue)
        """

        registerAppMessages(for: device)
    }

    private func registerAppMessages(for device: IQDevice) {
        guard let ciq else {
            status = "ConnectIQ unavailable during app registration"
            return
        }

        guard let watchAppUUID = UUID(uuidString: Self.watchAppUUIDString) else {
            status = "Invalid watch app UUID"
            lastMessage = Self.watchAppUUIDString
            return
        }

        let app = IQApp(
            uuid: watchAppUUID,
            store: nil,
            device: device
        )

        activeApp = app
        listenerRegistered = false

        status = "Checking FitConnect app on watch"

        ciq.getAppStatus(app) { [weak self] appStatus in
            guard let self else { return }

            guard let appStatus else {
                self.activeApp = nil
                self.status = "App status lookup returned nil"
                self.lastMessage = "Could not query FitConnect on selected watch"
                return
            }

            self.lastMessage = "App status: \(String(describing: appStatus))"

            guard appStatus.isInstalled else {
                self.activeApp = nil
                self.listenerRegistered = false
                self.status = "FitConnect watch app is not installed"
                return
            }

            ciq.unregister(forAppMessages: app, delegate: self)
            ciq.register(forAppMessages: app, delegate: self)

            self.listenerRegistered = true
            self.status = "Physical watch listener registered"
            self.lastMessage = "Registered app UUID:\n\(Self.watchAppUUIDString)"
        }
    }

    func deviceStatusChanged(_ device: IQDevice!, status deviceStatus: IQDeviceStatus) {
        guard let device else {
            status = "Received device status without device"
            return
        }

        selectedDevice = device

        switch deviceStatus {
        case .connected:
            status = "Watch connected"
            lastMessage = "Waiting for characteristics discovery"

        case .bluetoothNotReady:
            clearConnectionState(status: "Bluetooth not ready")

        case .invalidDevice:
            clearConnectionState(status: "Invalid Garmin device")

        case .notConnected:
            clearConnectionState(status: "Watch disconnected")

        case .notFound:
            clearConnectionState(status: "Garmin watch not found")

        @unknown default:
            status = "Unknown device status"
            lastMessage = "Raw status: \(deviceStatus.rawValue)"
        }
    }

    func deviceCharacteristicsDiscovered(_ device: IQDevice!) {
        guard let device else {
            status = "Characteristics discovered without device"
            return
        }

        selectedDevice = device
        deviceReadyForCommunication = true
        status = "Watch ready for communication"

        registerAppMessages(for: device)
    }

    func receivedMessage(_ message: Any!, from app: IQApp!) {
        guard let message else {
            status = "Received empty watch message"
            lastMessage = "Empty message"
            return
        }

        receivedMessageCount += 1
        lastReceivedAt = Int64(Date().timeIntervalSince1970 * 1000)

        status = "Message received"
        lastMessage = """
        App: \(String(describing: app))
        Message:
        \(formatMessage(message))
        """
    }

    func sendPingToWatch() {
        guard let ciq else {
            status = "Cannot send: ConnectIQ unavailable"
            return
        }

        guard let app = activeApp else {
            status = "Cannot send: app not registered"
            return
        }

        guard deviceReadyForCommunication else {
            status = "Cannot send: watch not ready"
            return
        }

        guard listenerRegistered else {
            status = "Cannot send: listener not registered"
            return
        }

        let payload: NSDictionary = [
            "type": "ping",
            "source": "ios",
            "message": "hello from iPhone",
            "timestamp": NSNumber(value: Int64(Date().timeIntervalSince1970 * 1000))
        ]

        status = "Sending iPhone ping"

        ciq.sendMessage(
            payload,
            to: app,
            progress: nil
        ) { [weak self] result in
            self?.status = "iPhone send result: \(result)"
            self?.lastMessage = "iPhone → Watch payload attempted"
        }
    }

    func needsToInstallConnectMobile() {
        status = "Garmin Connect is required"
        lastMessage = "Install/open Garmin Connect and pair the Fenix."
    }

    func shutdown() {
        ciq?.unregister(forAllDeviceEvents: self)
        ciq?.unregister(forAllAppMessages: self)

        clearConnectionState(status: "Garmin SDK listeners removed")
    }

    func getDebugStatus() -> String {
        status
    }

    func getDebugMessage() -> String {
        lastMessage
    }

    func isPhysicalDeviceMode() -> Bool {
        true
    }

    private func clearConnectionState(status newStatus: String) {
        selectedDevice = nil
        activeApp = nil
        listenerRegistered = false
        deviceReadyForCommunication = false
        status = newStatus
    }

    private func formatMessage(_ message: Any) -> String {
        guard JSONSerialization.isValidJSONObject(message) else {
            return String(describing: message)
        }

        guard
            let data = try? JSONSerialization.data(
                withJSONObject: message,
                options: [.prettyPrinted, .sortedKeys]
            ),
            let text = String(data: data, encoding: .utf8)
        else {
            return String(describing: message)
        }

        return text
    }
}
