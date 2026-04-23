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
    
    // MARK: - Constraints
    static let streetMin = 3
    static let streetMax = 60
    static let cityMin = 2
    static let cityMax = 40
    static let countryMin = 2
    static let countryMax = 40
    static let postalCodeMin = 3
    static let postalCodeMax = 12
    
    // MARK: - Fields
    @Published var street: String = "" {
        didSet {
            if street.count > Self.streetMax {
                street = String(street.prefix(Self.streetMax))
            }
        }
    }
    @Published var city: String = "" {
        didSet {
            if city.count > Self.cityMax {
                city = String(city.prefix(Self.cityMax))
            }
        }
    }
    @Published var country: String = "" {
        didSet {
            if country.count > Self.countryMax {
                country = String(country.prefix(Self.countryMax))
            }
        }
    }
    @Published var postalCode: String = "" {
        didSet {
            if postalCode.count > Self.postalCodeMax {
                postalCode = String(postalCode.prefix(Self.postalCodeMax))
            }
        }
    }
   
    // MARK: - Dependencies
    private let mode: AddressFormMode
    private let client: Client
    private let repo: AddressRepository
    init(mode: AddressFormMode, client: Client, repo: AddressRepository) {
        self.mode = mode
        self.client = client
        self.repo = repo
        if case .edit(let address) = mode {
            street = String((address.street ?? "").prefix(Self.streetMax))
            city = String((address.city ?? "").prefix(Self.cityMax))
            country = String((address.country ?? "").prefix(Self.countryMax))
            postalCode = String(
                (address.postalCode ?? "").prefix(Self.postalCodeMax)
            )
        }
    }
   
    // MARK: - Titles
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
    
    // MARK: - Validation
    private var trimmedStreet: String {
        street.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedCity: String {
        city.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedCountry: String {
        country.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedPostalCode: String {
        postalCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var isValid: Bool {
        trimmedStreet.count >= Self.streetMin
            && trimmedCity.count >= Self.cityMin
            && trimmedCountry.count >= Self.countryMin
            && trimmedCountry.count <= Self.countryMax
            && trimmedPostalCode.count >= Self.postalCodeMin
    }
   
    // MARK: - Save
    func save() throws {
        switch mode {
        case .create:
            try repo.create(
                for: client,
                street: trimmedStreet,
                city: trimmedCity,
                country: trimmedCountry,
                postalCode: trimmedPostalCode
            )
        case .edit(let address):
            try repo.update(
                address,
                street: trimmedStreet,
                city: trimmedCity,
                country: trimmedCountry,
                postalCode: trimmedPostalCode
            )
        }
    }
}
