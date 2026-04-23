//
//  AddressRepository.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData

protocol AddressRepository {
    func fetchAll(for client: Client) throws -> [Address]
    func create(
        for client: Client,
        street: String,
        city: String,
        country: String,
        postalCode: String
    ) throws
    func update(
        _ address: Address,
        street: String,
        city: String,
        country: String,
        postalCode: String
    ) throws
    func delete(_ address: Address) throws
}

final class CoreDataAddressRepository: AddressRepository {
    private let context: NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    func fetchAll(for client: Client) throws -> [Address] {
        let request: NSFetchRequest<Address> = Address.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try context.fetch(request)
    }
    func create(
        for client: Client,
        street: String,
        city: String,
        country: String,
        postalCode: String
    ) throws {
        _ = Address.make(
            in: context,
            client: client,
            street: street,
            city: city,
            country: country,
            postalCode: postalCode
        )
        try context.save()
    }
    func update(
        _ address: Address,
        street: String,
        city: String,
        country: String,
        postalCode: String
    ) throws {
        address.street = street
        address.city = city
        address.country = country
        address.postalCode = postalCode
        try context.save()
    }
    func delete(_ address: Address) throws {
        context.delete(address)
        try context.save()
    }
}
