//
//  Client+Extensions.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//
import CoreData

extension Client {
    var addressList: [Address] {
        let set = addresses as? Set<Address> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    static func make(in ctx: NSManagedObjectContext, companyName: String, email: String, phone: String) -> Client {
        let c = Client(context: ctx)
        c.id = UUID()
        c.companyName = companyName
        c.email = email
        c.phone = phone
        c.createdAt = Date()
        return c
    }
}
