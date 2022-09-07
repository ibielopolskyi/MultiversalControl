//
//  MDNSModel.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/6/22.
//

import Foundation
import Network
import CoreData
import IOBluetooth

struct MDNSModel {
    let context = PersistenceController.shared.container.newBackgroundContext()
    var monitor: String
    var peripherals: Array<IOBluetoothDevice>

    init(fromDict: [String: String]){
        self.monitor = fromDict["m"]!
        self.peripherals = []
        let jsonDecoder = JSONDecoder()
        do {
            let ids = try jsonDecoder.decode([String].self, from: fromDict["ids"]!.data(using: .utf8)!)
            for id in ids {
                self.peripherals.append(IOBluetoothDevice(addressString: id))
            }
        } catch {
            print("JSON decoding failed")
            print(error)
        }
    }
    
    init(fromData: Monitor) {
        self.monitor = fromData.name!
        self.peripherals = []
        for item in fromData.peripherals! {
            if let peripheral = item as? Peripherals {
                self.peripherals.append(IOBluetoothDevice(addressString: peripheral.id))
            }
        }
    }

    init(monitor: String, ids: [String]) {
        self.monitor = monitor
        self.peripherals = []
        for id in ids {
            self.peripherals.append(IOBluetoothDevice(addressString: id))
        }
                    
    }

    init(monitor: String, devices: [IOBluetoothDevice]) {
        self.monitor = monitor
        self.peripherals = []
        for id in devices {
            self.peripherals.append(id)
        }
    }

    func to_dns() throws -> NWTXTRecord {
        var ids: Array<String> = []
        for peripheral in self.peripherals{
            if peripheral.isConnected() {
                ids.append(peripheral.addressString)
            }
        }
        return NWTXTRecord(["m":self.monitor, "ids":String(decoding: try JSONEncoder().encode(ids), as: UTF8.self)])
    }
    
    func saveMonitor(remote: Bool) {
        let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                if (object.name == monitor){
                    if (!object.local) {
                        object.local = !remote
                        do {
                            try context.save()
                        } catch {
                            print(error)
                            print("failed to save monitor")
                        }
                    }
                    return
                }
            }
            
            let monitorInstance = Monitor(context: context)
            monitorInstance.name = monitor
            monitorInstance.local = !remote
        } catch {
            print(error)
            print("failed to run monitor save")
        }
        do {
            try context.save()
        } catch {
            print(error)
            print("failed to save monitor")
        }
    }

    func save(remote: Bool) {
        saveMonitor(remote: remote)
        let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                if (object.name == monitor) {
                    if (!remote || object.peripherals?.allObjects.count == 0) {
                        object.peripherals = []
                        for device in peripherals {
                            let peripheral = Peripherals(context: context)
                            peripheral.id = device.addressString
                            peripheral.human_readable_name = device.name
                            peripheral.ignore = false
                            object.addToPeripherals(peripheral)
                        }
                    }
                }
            }
        } catch {
            print(error)
            print("failed to run monitor disconnect")
        }

        do {
            try context.save()
        } catch {
            print("failed to save")
        }
        do {
            if(!remote) {
                reAdvertise(txtRecord: try to_dns())
            }
        } catch {
            print("Failed to re-advertise")
        }
    }
}
