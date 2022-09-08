//
//  MonitorController.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import Foundation
import Cocoa
import SwiftUI
import CoreData


var monitorController = MonitorController()

class MonitorController {
    let context = PersistenceController.shared.container.newBackgroundContext()
    var externalMonitors: Set<String> = Set(NSScreen.externalScreens().map { $0.localizedName })
    var externalDisplayCount:Int = NSScreen.externalScreens().count

    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayConnection),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
    }

    @objc func handleDisplayConnection(notification: Notification) {
        let currentScreens = NSScreen.externalScreens()
        if externalDisplayCount < currentScreens.count {
            print("An external display was connected.")
            for monitor in Monitor.getLocal(context: context) {
                monitor.onConnect()
            }
        } else if externalDisplayCount > currentScreens.count {
            print("An external display was disconnected")
            let currentLocal = Set(Monitor.getLocal(context: context).map { $0.name! })
            for screen in externalMonitors.subtracting(currentLocal) {
                Monitor.byName(context: context, name:screen).onDisconnect()
            }
        } else {
            print("A display configuration change occurred.")
        }
        externalMonitors = Set(currentScreens.map { $0.localizedName })
        externalDisplayCount = currentScreens.count
    }
}


extension NSScreen {
    class func externalScreens() -> [NSScreen] {
        let description: NSDeviceDescriptionKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        return screens.filter {
            guard let deviceID = $0.deviceDescription[description] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(deviceID.uint32Value) == 0
        }
    }
}
