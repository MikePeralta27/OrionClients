//
//  ClientCardView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//
import CoreData
import SwiftUI

struct ClientCardView: View {
    @ObservedObject var client: Client
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 44, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            Text(client.companyName ?? "Untitled")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

#Preview {
    ClientCardView(
        client: {
            let ctx = PersistenceController.preview.container.viewContext
            return Client.make(
                in: ctx,
                companyName: "Acme Corp",
                email: "hello@acme.com",
                phone: "+1 555 0100"
            )
        }()
    )
    .padding()
    .frame(width: 180)
}
