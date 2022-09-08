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
    
    @objc func hideMonitor(_ sender: NSMenuItem) {
        let context = persistenceController.container.viewContext
        let monitor = Monitor.byName(context: context, name:sender.title)
        monitor.ignore = !monitor.ignore
        do {
            try context.save()
        } catch {
            print("Failed to save monitor ignore")
            print(error)
        }
        //sender.state = monitor.ignore ? .off : .on
    }
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let context = persistenceController.container.viewContext
        let mainMenu = NSMenu(title:"Settings")
                
        // The titles of the menu items are for identification purposes only and shouldn't be localized.
        // The strings in the menu bar come from the submenu titles,
        // except for the application menu, whose title is ignored at runtime.
        let menuItem = mainMenu.addItem(withTitle:"Monitors", action:nil, keyEquivalent:"")
        let submenu = NSMenu(title:"Monitors")
        for monitor in Monitor.getAll(context: context) {
            let item = NSMenuItem(title: monitor.name!, action: #selector(hideMonitor), keyEquivalent: "")
            item.state = monitor.ignore ? .off : .on
            submenu.addItem(item)
        }
        mainMenu.setSubmenu(submenu, for:menuItem)
        return mainMenu
    }
    func applicationWillFinishLaunching(_ notification: Notification) {
        let context = persistenceController.container.viewContext
        setBluetoothController(context: context)
        setMonitorController(context: context)
        reBrowse(context: context)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        bluetoothController!.start()
        monitorController!.setupNotificationCenter()

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
