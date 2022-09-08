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

var monitorController: MonitorController?

public func setMonitorController(context: NSManagedObjectContext) {
    monitorController = MonitorController(context: context)
}

class MonitorController {
    let context: NSManagedObjectContext
    
    init (context: NSManagedObjectContext) {
        self.context = context
    }
    var externalMonitors: Set<String> = Set(NSScreen.externalScreens().map { $0.localizedName })
    var externalDisplayCount:Int = NSScreen.externalScreens().count

    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayConnection),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(handleDisplayConnection),
                name: NSWorkspace.didWakeNotification, object: nil)

    }

    @objc func handleDisplayConnection(notification: Notification) {
        print(notification)
        let currentScreens = NSScreen.externalScreens()
        if externalDisplayCount <= currentScreens.count {
            print("Display change has occured")
            for monitor in Monitor.getLocal(context: context) {
                monitor.onConnect()
                do {
                    try context.save()
                } catch {
                    print("External display connection has failed")
                    print(error)
                }
            }
        } else if externalDisplayCount > currentScreens.count {
            print("An external display was disconnected")
            let currentLocal = Set(Monitor.getLocal(context: context).map { $0.name! })
            for screen in externalMonitors.subtracting(currentLocal) {
                Monitor.byName(context: context, name:screen).onDisconnect()
                do {
                    try context.save()
                } catch {
                    print("External display disconnection has failed")
                    print(error)
                }
            }
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
