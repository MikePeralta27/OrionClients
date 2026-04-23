//
//  iClientsApp.swift
//  iClients
//
//  Created by Michael Peralta on 4/21/26.
//

import CoreData
import SwiftUI

@main
struct iClientsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}
