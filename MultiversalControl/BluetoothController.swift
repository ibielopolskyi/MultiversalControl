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
        if self.device.isPaired() && !self.device.isConnected() {
            self.device.openConnection()
        } else if !self.device.isPaired() {
            print("pairing finished and no paired")
        } else {
            print("Device already connected")
        }
    }
    
    func deviceSimplePairingComplete(
        _ sender: Any!,
        status: BluetoothHCIEventStatus
    ) {
        if self.device.isPaired() && !self.device.isConnected() {
            self.device.openConnection()
        } else if !self.device.isPaired() {
            print("pairing finished simple complete and no paired")
        } else {
            print("Device already connected")
        }
    }
    
}

class BluetoothController {
    let context: NSManagedObjectContext
    
    init (context: NSManagedObjectContext) {
        self.context = context
    }
    
    @objc func handleConnect(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        for monitor in Monitor.getLocal(context: context) {
            monitor.addDevice(id: device.addressString)
            do {
                try context.save()
            } catch {
                print("Handle connect save failed")
                print(error)
            }
            reAdvertise(monitor: monitor)
        }
    }

    @objc func handleDisconnect(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        for monitor in Monitor.getLocal(context: context) {
            monitor.removeDevice(id: device.addressString)
            do {
                try context.save()
            } catch {
                print("Handle disconnect save failed")
                print(error)
            }
            reAdvertise(monitor: monitor)
        }
       
    }

    func start() {
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(handleConnect))
        guard let devices = IOBluetoothDevice.pairedDevices() else {
            print("No devices")
            return
        }
        
        for item in devices {
            if let device = item as? IOBluetoothDevice {
                device.register(forDisconnectNotification: self, selector: #selector(handleDisconnect))
            }
        }
    }
}
