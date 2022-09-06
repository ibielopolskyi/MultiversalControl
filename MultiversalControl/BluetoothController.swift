//
//  BluetoothController.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//
import IOBluetooth
import Foundation
import Cocoa
import CoreData

var bluetoothController = BluetoothController()

class PairDelegate : NSObject, IOBluetoothDevicePairDelegate {
    let klass: IOBluetoothDevicePair
    let device: IOBluetoothDevice

    init(device: IOBluetoothDevice) {
        self.klass = IOBluetoothDevicePair(device: device)
        self.device = device
        super.init()
        
        klass.delegate = self
    }
    func start() -> IOReturn {
        return klass.start()
    }
    func devicePairingFinished(
        _ sender: Any!,
        error: IOReturn
    ) {
        if self.device.isPaired(){
            print("connecting")
            self.device.openConnection()
        } else {
            print("pairing finished and no paired")
        }
    }
    
    func deviceSimplePairingComplete(
        _ sender: Any!,
        status: BluetoothHCIEventStatus
    ) {
        if self.device.isPaired(){
            print("connecting")
            self.device.openConnection()
        } else {
            print("pairing finished simple complete and no paired")
        }
    }
    
}

class BluetoothController {
    let context = PersistenceController.shared.container.newBackgroundContext()
    
    func pair(device: IOBluetoothDevice) -> IOReturn {
        if(!device.isPaired()) {
            let pairing = PairDelegate(device:device)
            return pairing.klass.start()
        }
        return IOReturn.zero
    }
    
    func connect(device: IOBluetoothDevice) -> IOReturn {
        if(!device.isConnected()){
            return device.openConnection()
        }
        return IOReturn.zero
    }

    @objc func handleDevices () {
        guard let devices = IOBluetoothDevice.pairedDevices() else {
            print("No devices")
            return
        }
        var connectedDevices : [IOBluetoothDevice] = []
        for item in devices {
            if let device = item as? IOBluetoothDevice {
                if (device.isConnected()) {
                    connectedDevices.append(device)
                }
            }
        }
        let fetchRequest: NSFetchRequest<Monitor> = Monitor.fetchRequest()
//        fetchRequest.predicate = NSPredicate(
//            format: "local = true"
//        )
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects{
                MDNSModel(monitor: object.name!, devices: connectedDevices).save(remote: !object.local)
            }
        } catch {
            print(error)
            print("failed to fetch local monitors while updating bluetooth")
        }
    }

    func start() {
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(handleDevices))
        guard let devices = IOBluetoothDevice.pairedDevices() else {
            print("No devices")
            return
        }
        
        for item in devices {
            if let device = item as? IOBluetoothDevice {
                device.register(forDisconnectNotification: self, selector: #selector(handleDevices))
            }
        }
    }
}
