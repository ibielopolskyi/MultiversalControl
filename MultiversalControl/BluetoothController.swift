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
            self.device.openConnection()
        } else {
            print("pairing finished simple complete and no paired")
        }
    }
    
}

class BluetoothController {
    let context = PersistenceController.shared.container.newBackgroundContext()
    
    @objc func handleConnect(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        for monitor in Monitor.getLocal(context: context) {
            monitor.addDevice(id: device.addressString)
            reAdvertise(monitor: monitor)
        }
    }

    @objc func handleDisconnect(notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        for monitor in Monitor.getLocal(context: context) {
            monitor.removeDevice(id: device.addressString)
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
