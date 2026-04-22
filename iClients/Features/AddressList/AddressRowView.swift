//
//  AddressRowView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct AddressRowView: View {
    @ObservedObject var address: Address
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(address.street ?? "—")
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            if !secondaryLine.isEmpty {
                Text(secondaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    private var secondaryLine: String {
        [address.city, address.country, address.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

#Preview {
    let ctx = PersistenceController.preview.container.viewContext
    let client = Client.make(
        in: ctx,
        companyName: "Acme Corp",
        email: "hello@acme.com",
        phone: "+1 555 0100"
    )
    let address = Address.make(
        in: ctx,
        client: client,
        street: "123 Main St",
        city: "New York",
        country: "USA",
        postalCode: "10001"
    )
    return List {
        AddressRowView(address: address)
    }
}
