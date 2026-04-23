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
   
    // MARK: - Constraints
    static let companyNameMin = 2
    static let companyNameMax = 30
    static let emailMin = 5
    static let emailMax = 50
    static let phoneMin = 7
    static let phoneMax = 20
    
    // MARK: - Format validators
    private static let emailRegex: NSRegularExpression = {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return try! NSRegularExpression(pattern: pattern)
    }()
    private static let phoneDetector: NSDataDetector = {
        try! NSDataDetector(
            types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        )
    }()
    
    // MARK: - Fields
    @Published var companyName: String = "" {
        didSet {
            if companyName.count > Self.companyNameMax {
                companyName = String(companyName.prefix(Self.companyNameMax))
            }
        }
    }
    @Published var email: String = "" {
        didSet {
            if email.count > Self.emailMax {
                email = String(email.prefix(Self.emailMax))
            }
        }
    }
    @Published var phone: String = "" {
        didSet {
            if phone.count > Self.phoneMax {
                phone = String(phone.prefix(Self.phoneMax))
            }
        }
    }
    
    // MARK: - Dependencies
    private let mode: ClientFormMode
    private let repo: ClientRepository
    init(mode: ClientFormMode, repo: ClientRepository) {
        self.mode = mode
        self.repo = repo
        if case .edit(let client) = mode {
            companyName = String(
                (client.companyName ?? "").prefix(Self.companyNameMax)
            )
            email = String((client.email ?? "").prefix(Self.emailMax))
            phone = String((client.phone ?? "").prefix(Self.phoneMax))
        }
    }
    
    // MARK: - Titles
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
    
    // MARK: - Validation
    private var trimmedCompanyName: String {
        companyName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedPhone: String {
        phone.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var isEmailFormatValid: Bool {
        let trimmed = trimmedEmail
        guard !trimmed.isEmpty else { return false }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        return Self.emailRegex.firstMatch(in: trimmed, range: range) != nil
    }
    var isPhoneFormatValid: Bool {
        let trimmed = trimmedPhone
        guard !trimmed.isEmpty else { return false }
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard
            let match = Self.phoneDetector.firstMatch(in: trimmed, range: range)
        else {
            return false
        }
        return match.range == range
    }
    var emailFormatError: String? {
        (trimmedEmail.count >= Self.emailMin && !isEmailFormatValid)
            ? "Enter a valid email address"
            : nil
    }
    var phoneFormatError: String? {
        (trimmedPhone.count >= Self.phoneMin && !isPhoneFormatValid)
            ? "Enter a valid phone number"
            : nil
    }
    var isValid: Bool {
        trimmedCompanyName.count >= Self.companyNameMin
            && trimmedEmail.count >= Self.emailMin
            && isEmailFormatValid
            && trimmedPhone.count >= Self.phoneMin
            && isPhoneFormatValid
    }
  
    // MARK: - Save
    func save() throws {
        switch mode {
        case .create:
            try repo.create(
                companyName: trimmedCompanyName,
                email: trimmedEmail,
                phone: trimmedPhone
            )
        case .edit(let client):
            try repo.update(
                client,
                companyName: trimmedCompanyName,
                email: trimmedEmail,
                phone: trimmedPhone
            )
        }
    }
}
