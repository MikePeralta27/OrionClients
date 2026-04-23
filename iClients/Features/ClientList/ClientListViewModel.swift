//
//  ClientListViewModel.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI
import Combine

@MainActor
final class ClientListViewModel: ObservableObject {
    @Published var formMode: ClientFormMode?

    @Published var selectedClient: Client?

    private let repo: ClientRepository

    init(repo: ClientRepository) {
        self.repo = repo
    }
    
    func delete(_ client: Client) {
        try? repo.delete(client)
    }
    
    func startCreate() {
        formMode = .create
    }
    
    func startEdit(_ client: Client) {
        formMode = .edit(client)
    }
    
}

enum ClientFormMode: Identifiable {
    case create
    case edit(Client)
    
    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let c): return c.id?.uuidString ?? "edit"
        }
    }
}
