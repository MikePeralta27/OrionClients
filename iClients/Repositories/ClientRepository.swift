//
//  ClientRepository.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//
import CoreData

protocol ClientRepository {
    func fetchAll() throws -> [Client]
    func create(companyName: String, email: String, phone: String) throws
    func update(
        _ client: Client,
        companyName: String,
        email: String,
        phone: String
    ) throws
    func delete(_ client: Client) throws
}
final class CoreDataClientRepository: ClientRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    func fetchAll() throws -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return try context.fetch(request)
    }
    func create(companyName: String, email: String, phone: String) throws {
        _ = Client.make(
            in: context,
            companyName: companyName,
            email: email,
            phone: phone
        )
        try context.save()
    }
    func update(
        _ client: Client,
        companyName: String,
        email: String,
        phone: String
    ) throws {
        client.companyName = companyName
        client.email = email
        client.phone = phone
        try context.save()
    }
    func delete(_ client: Client) throws {
        context.delete(client)
        try context.save()
    }
}
