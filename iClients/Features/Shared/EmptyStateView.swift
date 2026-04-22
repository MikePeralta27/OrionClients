//
//  EmptyStateView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "tray"
    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
    }
}

#Preview {
    EmptyStateView(
        title: "No clients yet",
        message: "Tap + to add your first client.",
        systemImage: "person.2.slash"
    )
}
