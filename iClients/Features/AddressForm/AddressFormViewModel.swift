//
//  AddressFormViewModel.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import Combine
import CoreData
import SwiftUI

@MainActor
final class AddressFormViewModel: ObservableObject {
    static let maxPostalCodeLength = 12
    @Published var street: String = ""
    @Published var city: String = ""
    @Published var country: String = ""
    @Published var postalCode: String = "" {
        didSet {
            if postalCode.count > Self.maxPostalCodeLength {
                postalCode = String(postalCode.prefix(Self.maxPostalCodeLength))
            }
        }
    }
    private let mode: AddressFormMode
    private let client: Client
    private let repo: AddressRepository
    init(mode: AddressFormMode, client: Client, repo: AddressRepository) {
        self.mode = mode
        self.client = client
        self.repo = repo
        if case .edit(let address) = mode {
            street = address.street ?? ""
            city = address.city ?? ""
            country = address.country ?? ""
            let existingPostal = address.postalCode ?? ""
            postalCode = String(existingPostal.prefix(Self.maxPostalCodeLength))
        }
    }
    var title: String {
        switch mode {
        case .create: return "Add Address"
        case .edit: return "Edit Address"
        }
    }
    var saveButtonTitle: String {
        switch mode {
        case .create: return "Add"
        case .edit: return "Save"
        }
    }
    var isValid: Bool {
        let trimmedStreet = street.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedStreet.isEmpty && !trimmedCity.isEmpty
    }
    func save() throws {
        let trimmedStreet = street.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = country.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedPostal = postalCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        switch mode {
        case .create:
            try repo.create(
                for: client,
                street: trimmedStreet,
                city: trimmedCity,
                country: trimmedCountry,
                postalCode: trimmedPostal
            )
        case .edit(let address):
            try repo.update(
                address,
                street: trimmedStreet,
                city: trimmedCity,
                country: trimmedCountry,
                postalCode: trimmedPostal
            )
        }
    }
}
