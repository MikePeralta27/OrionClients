//
//  OrionClientsApp.swift
//  OrionClients
//
//  Created by Michael Peralta on 4/21/26.
//

import SwiftUI
import CoreData

@main
struct OrionClientsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
