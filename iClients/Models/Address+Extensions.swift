//
//  Address+Extensions.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//
import CoreData

extension Address {
    static func make(
        in ctx: NSManagedObjectContext,
        client: Client,
        street: String,
        city: String,
        country: String,
        postalCode: String
    ) -> Address {
        let a = Address(context: ctx)
        a.id = UUID()
        a.street = street
        a.city = city
        a.country = country
        a.postalCode = postalCode
        a.createdAt = Date()
        a.client = client
        return a
    }
}
