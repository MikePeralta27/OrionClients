//
//  FieldValidationFooter.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import SwiftUI

struct FieldValidationFooter: View {
    let count: Int
    let minLength: Int
    let maxLength: Int
    let isRequired: Bool
    var formatError: String? = nil
    var body: some View {
        HStack {
            if !hintText.isEmpty {
                Text(hintText)
                    .foregroundStyle(hintColor)
            }
            Spacer()
            Text("\(count)/\(maxLength)")
                .monospacedDigit()
                .foregroundStyle(counterColor)
        }
    }
    private var hintText: String {
        if isRequired && count == 0 {
            return "Required"
        }
        if count > 0 && count < minLength {
            return "At least \(minLength) characters"
        }
        if let formatError, count >= minLength {
            return formatError
        }
        if count >= maxLength {
            return "Maximum reached"
        }
        return ""
    }
    private var hintColor: Color {
        if count > 0 && count < minLength { return .orange }
        if formatError != nil && count >= minLength { return .orange }
        if count >= maxLength { return .orange }
        return .secondary
    }
    private var counterColor: Color {
        count >= maxLength ? .orange : .secondary
    }
}
#Preview {
    Form {
        Section {
            TextField("Email", text: .constant("notanemail"))
        } footer: {
            FieldValidationFooter(
                count: 10,
                minLength: 5,
                maxLength: 50,
                isRequired: true,
                formatError: "Enter a valid email address"
            )
        }
        Section {
            TextField("Phone", text: .constant("555-1234"))
        } footer: {
            FieldValidationFooter(
                count: 8,
                minLength: 7,
                maxLength: 20,
                isRequired: true,
                formatError: nil
            )
        }
    }
}
