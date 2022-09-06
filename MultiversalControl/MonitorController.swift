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

extension NSScreen {
    class func externalScreens() -> [NSScreen] {
        let description: NSDeviceDescriptionKey = NSDeviceDescriptionKey(rawValue: "NSScreenNumber")
        return screens.filter {
            guard let deviceID = $0.deviceDescription[description] as? NSNumber else { return false }
            return CGDisplayIsBuiltin(deviceID.uint32Value) == 0
        }
    }
}

var monitorController = MonitorController()

class MonitorController {
    let context = PersistenceController.shared.container.newBackgroundContext()
    
    var externalDisplayCount:Int = 1

    func setupNotificationCenter() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayConnection),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
        saveScreens()

    }
    func resetLocal() {
        let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "local = true"
        )
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects{
                object.local = false
            }
        } catch {
            print(error)
            print("failed to fetch local monitors while updating screens")
        }
        do {
            try context.save()
        } catch {
            print("failed to save")
        }
    }

    func saveScreens() {
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        resetLocal()
        let externalScreens = NSScreen.externalScreens()
        externalDisplayCount = externalScreens.count
        for screen in externalScreens {
            print(screen.localizedName)
            let ids: [String] = []
            MDNSModel(monitor:screen.localizedName, ids : ids).saveMonitor(remote:false)
        }
    }

    @objc func handleDisplayConnection(notification: Notification) {
        if externalDisplayCount < NSScreen.externalScreens().count {
            print("An external display was connected.")
            saveScreens()
            let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "local = true"
            )
            do {
                let objects = try context.fetch(fetchRequest)
                for object in objects{
                    let model = MDNSModel(fromData:object)
                    for peripherial in model.peripherals {
                        peripherial.openConnection()
                        
                    }
                    saveScreens()
                }
            } catch {
                print(error)
                print("failed to run monitor connect")
            }
        } else if externalDisplayCount > NSScreen.externalScreens().count {
            print("An external display was disconnected.")
            let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "local = true"
            )
            do {
                let objects = try context.fetch(fetchRequest)
                for object in objects{
                    let model = MDNSModel(fromData:object)
                    let server = try Server(txtRecord:model.to_dns())
                    for peripherial in model.peripherals {
                        peripherial.unpair()
                    }
                    server.stop()
                }
                saveScreens()
            } catch {
                print(error)
                print("failed to run monitor disconnect")
            }
        } else {
            print("A display configuration change occurred.")
        }
        
        externalDisplayCount = NSScreen.externalScreens().count
    }
}
