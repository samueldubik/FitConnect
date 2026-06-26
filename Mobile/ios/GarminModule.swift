import Foundation
import React

@objc(GarminModule)
final class GarminModule: NSObject {

    @objc
    static func requiresMainQueueSetup() -> Bool {
        false
    }

  @objc(getDebugStatus:rejecter:)
  func getDebugStatus(
      _ resolve: @escaping RCTPromiseResolveBlock,
      rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
      resolve(GarminManager.shared.getDebugStatus())
  }

  @objc(getDebugMessage:rejecter:)
  func getDebugMessage(
      _ resolve: @escaping RCTPromiseResolveBlock,
      rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
      resolve(GarminManager.shared.getDebugMessage())
  }

    @objc(refreshDevicesAndRegister:rejecter:)
    func refreshDevicesAndRegister(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            GarminManager.shared.refreshDevicesAndRegister()
            resolve(GarminManager.shared.getDebugStatus())
        }
    }

    @objc(requestDeviceSelection:rejecter:)
    func requestDeviceSelection(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            GarminManager.shared.requestDeviceSelection()
            resolve(GarminManager.shared.getDebugStatus())
        }
    }

    @objc(sendPingToWatch:rejecter:)
    func sendPingToWatch(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        DispatchQueue.main.async {
            GarminManager.shared.sendPingToWatch()
            resolve(GarminManager.shared.getDebugStatus())
        }
    }

    @objc(isPhysicalDeviceMode:rejecter:)
    func isPhysicalDeviceMode(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        resolve(GarminManager.shared.isPhysicalDeviceMode())
    }

    @objc(getReceivedMessageCount:rejecter:)
    func getReceivedMessageCount(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        resolve(GarminManager.shared.receivedMessageCount)
    }

    @objc(getLastReceivedAt:rejecter:)
    func getLastReceivedAt(
        _ resolve: @escaping RCTPromiseResolveBlock,
        rejecter reject: @escaping RCTPromiseRejectBlock
    ) {
        resolve(GarminManager.shared.lastReceivedAt)
    }
  
  @objc(getConnectionSnapshot:rejecter:)
  func getConnectionSnapshot(
      _ resolve: @escaping RCTPromiseResolveBlock,
      rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
      resolve([
          "status": GarminManager.shared.getDebugStatus(),
          "message": GarminManager.shared.getDebugMessage(),
          "receivedCount": GarminManager.shared.receivedMessageCount,
          "lastReceivedAt": GarminManager.shared.lastReceivedAt,
          "physicalDeviceMode": GarminManager.shared.isPhysicalDeviceMode()
      ])
  }

  @objc(refreshConnection:rejecter:)
  func refreshConnection(
      _ resolve: @escaping RCTPromiseResolveBlock,
      rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
      DispatchQueue.main.async {
          GarminManager.shared.refreshDevicesAndRegister()
          resolve(nil)
      }
  }
}
