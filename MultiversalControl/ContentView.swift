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
        sortDescriptors: [NSSortDescriptor(keyPath: \Monitor.name, ascending: false)],
        animation: .default)
    private var items: FetchedResults<Monitor>


    struct Collapsible: View {
        @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Peripherals.id, ascending: false)],
            animation: .default)
        private var peripherials: FetchedResults<Peripherals>

        @State var monitor: Monitor
        @State private var collapsed: Bool = true

        func doIgnore(peripheral: Peripherals) {
            peripheral.ignore = !peripheral.ignore
            reAdvertise(monitor: monitor)
        }
        
        var body: some View {
            VStack {
            Button(
                action: { self.collapsed.toggle() },
                label: {
                    HStack {
                        Image(
                            nsImage:NSImage(
                                systemSymbolName: self.monitor.local ? "display" : "wifi",
                                accessibilityDescription: "These are the active monitor peripherals"
                            )!
                        ).foregroundColor(.green).frame(alignment: .leading)
                        Spacer()
                        Text(self.monitor.name!)
                        Spacer()
                        Image(systemName: self.collapsed ? "chevron.down" : "chevron.up").frame(alignment: .trailing)
                    }
                }
            ).buttonStyle(.borderedProminent)
            Divider()
            ForEach(peripherials){ peripheral in
                if (peripheral.relationship!.name! == monitor.name! && !peripheral.lost) {
                    Button(
                        action: { doIgnore(peripheral: peripheral) },
                        label: {
                                HStack() {
                                if (peripheral.isConnected()) {
                                    Image(
                                        nsImage:NSImage(
                                            systemSymbolName:  "keyboard.macwindow",
                                            accessibilityDescription: "These are the active monitor peripherals"
                                        )!
                                    ).frame(alignment: .leading).foregroundColor(.green)
                                } else if (peripheral.isLoading() && monitor.local) {
                                    ProgressView().controlSize(.small).frame(alignment: .leading)
                                } else {
                                    EmptyView()
                                }
                                Spacer()
                                    Text(peripheral.displayName() + (peripheral.ignore ? " (ignored)" : ""))
                                Spacer()
                            }
                        })
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: collapsed ? 0 : .none)
                        //.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .none)
                        .clipped()
                        .animation(.easeOut, value: 5)
                        .transition(.slide)
                    }
                }
            }
        }
    }

    var body: some View {
        List() {
            ForEach(items) { monitor in
                Collapsible(monitor: monitor)
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
