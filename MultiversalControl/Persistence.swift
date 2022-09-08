//
//  Persistence.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//
import Foundation
import CoreData
import Cocoa
import Network


public extension Peripherals {
    func isConnected() -> Bool {
        return device().isConnected()
    }
    
    func isPaired() -> Bool {
        return device().isPaired()
    }
    
    func isLoading() -> Bool {
        return (isConnected() == false) && (isPaired() == true)
    }

    func unpair() -> IOReturn {
        if ignore {
            return 1
        }
        return device().unpair()
    }

    func displayName() -> String {
        return device().name
    }

    func device() -> IOBluetoothDevice {
        return IOBluetoothDevice(addressString: self.id)!
    }

    func pair() -> IOReturn {
        if ignore {
            return 1
        }
        if(!isPaired()) {
            let pairing = PairDelegate(device:device())
            return pairing.klass.start()
        }
        return IOReturn.zero
    }
    
    func connect() -> IOReturn {
        if(!device().isConnected()){
            return device().openConnection()
        }
        return IOReturn.zero
    }
}


public extension Monitor {

    static func getLocal(context: NSManagedObjectContext) -> [Monitor] {
        var monitors: [Monitor] = []
        for screen in NSScreen.externalScreens() {
            monitors.append(Monitor.byName(context: context, name: screen.localizedName))
        }
        return monitors
    }

    static func byName(context: NSManagedObjectContext, name: String) -> Monitor {
        var monitor: Monitor?
        let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "name = %@", name
        )

        do {
            monitor = try context.fetch(fetchRequest).first
            if(monitor == nil) {
                monitor = Monitor(context: context)
                monitor!.name = name
                for screen in NSScreen.externalScreens() {
                    if (screen.localizedName == name) {
                        monitor!.local = true
                    }
                }
            }
        } catch {
            print("failed while retreiving monitor")
        }
        return monitor!
    }

    func releaseRemote() {
        if (!isConnected()) {
            for peripherial in peripheralsList() {
                if !(peripherial.ignore) {
                    _ = peripherial.unpair()
                }
            }
        }
    }

    func isConnected() -> Bool {
        return NSScreen.externalScreens().map { $0.localizedName }.contains(self.name!)
    }
    
    func onConnect() {
        self.local = true
        for peripherial in peripheralsList() {
            if !(peripherial.ignore) {
                _ = peripherial.pair()
            }
        }
    }
    
    func onDisconnect() {
        self.local = false
        for peripherial in peripheralsList() {
            if !(peripherial.ignore) {
                _ = peripherial.unpair()
            }
        }
    }

    func addDevice(id: String) {
        for peripheral in peripheralsList(includeLost: true).filter({ return $0.id == id }) {
            print("Existing device update")
            peripheral.lost = false
            return
        }
        let peripheral = Peripherals(context: managedObjectContext!)
        peripheral.id = id
        peripheral.ignore = false
        peripheral.lost = false
        addToPeripherals(peripheral)
    }

    func peripheralsList() -> [Peripherals] {
        return peripheralsList(includeLost: false)
    }

    func peripheralsList(includeLost: Bool) -> [Peripherals] {
        var _peripherals: [Peripherals] = []
        for peripherial in peripherals?.allObjects as! [Peripherals] {
            if !(peripherial.lost) || includeLost {
                _peripherals.append(peripherial)
            }
        }
        return _peripherals
    }

    func removeDevice(id: String) {
        for peripherial in peripheralsList() {
            if peripherial.id == id {
                peripherial.lost = true
            }
        }
    }
    
    func to_dns() throws -> NWTXTRecord {
        var ids: Array<String> = []
        for peripheral in peripheralsList() {
            if peripheral.isConnected() && !peripheral.ignore {
                ids.append(peripheral.id!)
            }
        }
        return NWTXTRecord(["m":name!, "ids":String(decoding: try JSONEncoder().encode(ids), as: UTF8.self)])
    }

    func onDiscovery(data: [String: String]) {
        do {
            let jsonDecoder = JSONDecoder()
            let currentDevices = try jsonDecoder.decode([String].self, from: data["ids"]!.data(using: .utf8)!)

            for device in peripheralsList() {
                removeDevice(id: device.id!)
            }

            for device in currentDevices {
                addDevice(id: device)
            }
            releaseRemote()
        } catch {
            print("Something went wrong while discovery")
            print(error)
        }
    }
    
}

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MultiversalControl")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                
                //fatalError("Unresolved error \(error), \(error.userInfo)")
                print(error)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
