//
//  MultiversalControlApp.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import SwiftUI

@main
struct MultiversalControlApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
