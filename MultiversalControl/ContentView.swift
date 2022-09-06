//
//  ContentView.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Monitor.name, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Monitor>

    
    struct Collapsible<Content: View>: View {
        @State var content: () -> Content
        @State var monitor: Monitor

        
        @State var collapsed: Bool = true
        
        var body: some View {
            VStack {
                Button(
                    action: { self.collapsed.toggle() },
                    label: {
                        HStack {
                            Image(nsImage:NSImage(systemSymbolName: self.monitor.local ? "display" : "wifi", accessibilityDescription: "These are the active monitor peripherals")!).foregroundColor(.green).frame(alignment: .leading)
                            Spacer()
                            Text(self.monitor.name!)
                            Spacer()
                            Image(systemName: self.collapsed ? "chevron.down" : "chevron.up").frame(alignment: .trailing)
                        }
                        //.padding(.bottom, 1)
                    }
                ).buttonStyle(.borderedProminent)
                
                VStack {
                    self.content()
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
                .clipped()
                .animation(.easeOut, value: 5)
                .transition(.slide)
            }
        }
    }

    struct CollapsibleView: View {
        @State var monitor: Monitor
        @State var expanded: Bool

        func doReset(peripheral: Peripherals) {
            _ = peripheral.unpair()
            _ = peripheral.pair()
        }

        @ViewBuilder
        var body: some View {
            Collapsible(
                content: {
                    VStack {
                        Divider()
                        ForEach(Array(monitor.peripherals!) as! [Peripherals]){ peripheral in
                            Button(action: { doReset(peripheral: peripheral) }) {
                                HStack() {
                                    if (peripheral.isConnected()) {
                                        Image(nsImage:NSImage(systemSymbolName:  "keyboard.macwindow", accessibilityDescription: "These are the active monitor peripherals")!).frame(alignment: .leading).foregroundColor(.green)
                                    } else if (peripheral.isLoading() && monitor.local) {
                                        ProgressView().controlSize(.small).frame(alignment: .leading)
                                    } else {
                                        EmptyView()
                                    }
                                    Spacer()
                                    Text(peripheral.human_readable_name!)
                                    Spacer()
                                    
                                }
                            }.disabled(!monitor.local || peripheral.isConnected())
                        }
                    }
                },
                monitor: monitor
            )
        }
    }
    var body: some View {
        List() {
            ForEach(items) { monitor in
                CollapsibleView(monitor: monitor, expanded: monitor.local)
                Divider()
            }
        }
    }
}

public extension Text {
    func sectionHeaderStyle() -> some View {
        self
            .font(.system(.title3))
            .foregroundColor(.primary)
            .textCase(nil)
    }
}

public extension Peripherals {
    func isConnected() -> Bool {
        return IOBluetoothDevice(addressString: self.id)!.isConnected()
    }
    
    func isPaired() -> Bool {
        return IOBluetoothDevice(addressString: self.id)!.isPaired()
    }
    
    func isLoading() -> Bool {
        return (isConnected() == false) && (isPaired() == true)
    }
    func unpair() -> IOReturn {
        return IOBluetoothDevice(addressString: self.id)!.unpair()
    }

    func pair() -> IOReturn {
        return IOBluetoothDevice(addressString: self.id)!.unpair()
    }
}
