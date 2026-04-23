//
//  Persistence.swift
//  iClients
//
//  Created by Michael Peralta on 4/21/26.
//

import CoreData

struct PersistenceController {
    static let shared: PersistenceController = {
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            return PersistenceController(inMemory: true)
        }
        return PersistenceController()
    }()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let ctx = result.container.viewContext

        let acme = Client.make(
            in: ctx,
            companyName: "Acme Corp",
            email: "hello@acme.com",
            phone: "+1 555 0100"
        )
        _ = Address.make(
            in: ctx,
            client: acme,
            street: "123 Main St",
            city: "New York",
            country: "United States",
            postalCode: "10001"
        )
        _ = Address.make(
            in: ctx,
            client: acme,
            street: "500 Warehouse Rd",
            city: "Newark",
            country: "United States",
            postalCode: "07102"
        )
        let globex = Client.make(
            in: ctx,
            companyName: "Globex S.A.",
            email: "contact@globex.do",
            phone: "+1 809 555 0199"
        )
        _ = Address.make(
            in: ctx,
            client: globex,
            street: "Av. Winston Churchill 1099",
            city: "Santo Domingo",
            country: "Dominican Republic",
            postalCode: "10148"
        )
        _ = Address.make(
            in: ctx,
            client: globex,
            street: "Calle El Conde 55",
            city: "Santo Domingo",
            country: "Dominican Republic",
            postalCode: "10210"
        )
        do {
            try ctx.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "iClients")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }
}
