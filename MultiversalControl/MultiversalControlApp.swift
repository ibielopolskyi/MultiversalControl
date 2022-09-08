//
//  MultiversalControlApp.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//
import Foundation
import SwiftUI
import IOBluetooth


class AppDelegate: NSResponder, NSApplicationDelegate {
    let persistenceController = PersistenceController.shared
    var popover: NSPopover!
    var statusBar: StatusBarController!
    
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        let context = persistenceController.container.viewContext
        MonitorController(context: context).setupNotificationCenter()
        reBrowse(context: context)
        BluetoothController(context: context).start()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let window = NSApplication.shared.windows.first {
            window.close()
        }
        let contentView = ContentView().environment(\.managedObjectContext, persistenceController.container.viewContext)
        // Create the popover
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        statusBar = StatusBarController.init(popover)
    }

}

@main
struct MultiversalControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showMenuBarExtra") private var showMenuBarExtra = true
    @State var currentNumber: String = "1"
    var body: some Scene {
        WindowGroup() {
            EmptyView()
        }
    }
}
