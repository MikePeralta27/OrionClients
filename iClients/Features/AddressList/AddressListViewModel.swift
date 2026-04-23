//
//  AddressListViewModel.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import Combine
import CoreData
import SwiftUI

@MainActor
final class AddressListViewModel: ObservableObject {
    
    @Published var formMode: AddressFormMode?
    
    private let repo: AddressRepository
    
    init(repo: AddressRepository) {
        self.repo = repo
    }
    
    func delete(_ address: Address) {
        try? repo.delete(address)
    }
    
    func startCreate() {
        formMode = .create
    }
    
    func startEdit(_ address: Address) {
        formMode = .edit(address)
    }
}

enum AddressFormMode: Identifiable {
    case create
    case edit(Address)
    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let address):
            return address.id?.uuidString ?? "edit"
        }
    }
}
