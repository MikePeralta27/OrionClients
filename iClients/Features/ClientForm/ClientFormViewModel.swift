//
//  ClientFormViewModel.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import Combine
import CoreData
import SwiftUI

@MainActor
final class ClientFormViewModel: ObservableObject {
    static let maxCompanyNameLength = 30
    @Published var companyName: String = "" {
        didSet {
            if companyName.count > Self.maxCompanyNameLength {
                companyName = String(
                    companyName.prefix(Self.maxCompanyNameLength)
                )
            }
        }
    }
    @Published var email: String = ""
    @Published var phone: String = ""
    private let mode: ClientFormMode
    private let repo: ClientRepository
    init(mode: ClientFormMode, repo: ClientRepository) {
        self.mode = mode
        self.repo = repo
        if case .edit(let client) = mode {
            let name = client.companyName ?? ""
            companyName = String(name.prefix(Self.maxCompanyNameLength))
            email = client.email ?? ""
            phone = client.phone ?? ""
        }
    }
    var title: String {
        switch mode {
        case .create: return "Add Client"
        case .edit: return "Edit Client"
        }
    }
    var saveButtonTitle: String {
        switch mode {
        case .create: return "Add"
        case .edit: return "Save"
        }
    }
    var isValid: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    func save() throws {
        let trimmedName = companyName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        switch mode {
        case .create:
            try repo.create(
                companyName: trimmedName,
                email: trimmedEmail,
                phone: trimmedPhone
            )
        case .edit(let client):
            try repo.update(
                client,
                companyName: trimmedName,
                email: trimmedEmail,
                phone: trimmedPhone
            )
        }
    }
}
