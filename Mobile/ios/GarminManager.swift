import Foundation
import ConnectIQ

final class GarminManager: NSObject, IQDeviceEventDelegate, IQAppMessageDelegate, IQUIOverrideDelegate {
    static let shared = GarminManager()

    private static let watchAppUUIDString = "3051d135-d055-4657-8548-018c798198a5"

    // Must exactly match the URL Type configured in the iOS target Info tab.
    private static let returnURLScheme = "fitconnect"

    private var selectedDevice: IQDevice?
    private var activeApp: IQApp?
    private var listenerRegistered = false

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

      status = "Initializing ConnectIQ with scheme: \(Self.returnURLScheme)"

      ciq.initialize(
          withUrlScheme: Self.returnURLScheme,
          uiOverrideDelegate: self
      )

      lastMessage = """
      URL scheme: \(Self.returnURLScheme)
      Bundle display name: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "MISSING")
      Query schemes: \(Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") ?? "MISSING")
      """
  }

    // iOS equivalent of Android's refreshDevicesAndRegister().
    // If no device was selected yet, this opens Garmin Connect's device picker.
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

    // Call this from AppDelegate when Garmin Connect opens FitConnect via its URL scheme.
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme == Self.returnURLScheme else {
            return false
        }

        guard
            let ciq,
            let devices = ciq.parseDeviceSelectionResponse(from: url) as? [IQDevice],
            !devices.isEmpty
        else {
            status = "No Garmin devices returned"
            lastMessage = "Garmin Connect returned no compatible devices"
            return false
        }

        let device = devices[0]
        selectedDevice = device
        activeApp = nil
        listenerRegistered = false

        lastMessage =
            "Selected device:\n" +
            "Name: \(device.friendlyName ?? "Unknown")\n" +
            "Model: \(device.modelName ?? "Unknown")\n" +
            "Devices returned: \(devices.count)"

        registerDeviceEvents(for: device)
        return true
    }

    private func registerDeviceEvents(for device: IQDevice) {
        guard let ciq else {
            status = "ConnectIQ unavailable during device registration"
            return
        }

        ciq.register(forDeviceEvents: device, delegate: self)

        status = "Device events registered: \(device.friendlyName ?? "Unknown")"
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

        ciq.register(forAppMessages: app, delegate: self)

        listenerRegistered = true
        status = "Physical watch listener registered"
        lastMessage =
            "Registered app id:\n" +
            Self.watchAppUUIDString
    }

    func deviceStatusChanged(_ device: IQDevice!, status deviceStatus: IQDeviceStatus) {
        guard let device else {
            status = "Received device status without device"
            return
        }

        switch deviceStatus {
        case .connected:
            selectedDevice = device
            status = "Watch connected — discovering characteristics"

        case .bluetoothNotReady:
            clearConnectionState(
                status: "Bluetooth not ready"
            )

        case .invalidDevice:
            clearConnectionState(
                status: "Invalid Garmin device"
            )

        case .notConnected:
            clearConnectionState(
                status: "Watch disconnected"
            )

        case .notFound:
            clearConnectionState(
                status: "Garmin watch not found"
            )

        @unknown default:
            status = "Unknown device state: \(deviceStatus.rawValue)"
        }
    }

    // This is the real communication-ready point on current Garmin iOS SDK.
    func deviceCharacteristicsDiscovered(_ device: IQDevice!) {
        guard let device else {
            status = "Characteristics discovered without device"
            return
        }

        selectedDevice = device
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

        lastMessage =
            "App: \(String(describing: app))\n" +
            "Message:\n" +
            formatMessage(message)
    }

    func sendPingToWatch() {
        guard let ciq, let app = activeApp else {
            status = "Cannot send: watch/app unavailable"
            return
        }

        guard listenerRegistered else {
            status = "Cannot send: listener not registered"
            return
        }

        let payload: NSDictionary = [
            "type": "ping",
            "source": "ios",
            "timestamp": NSNumber(
                value: Int64(Date().timeIntervalSince1970 * 1000)
            )
        ]

        status = "Sending iPhone ping"

        ciq.sendMessage(
            payload,
            to: app,
            progress: nil
        ) { [weak self] result in
            self?.status = "iPhone send status: \(result)"
            self?.lastMessage = "iPhone → Watch ping attempted"
        }
    }

  func needsToInstallConnectMobile() {
      status = "Garmin SDK requested Garmin Connect"
      lastMessage = """
      Garmin Connect callback fired.
      URL scheme: \(Self.returnURLScheme)
      Query schemes: \(Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") ?? "MISSING")
      """
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
