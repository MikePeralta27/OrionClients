//
//  ClientFormView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ClientFormViewModel
    @State private var saveErrorMessage: String?

    init(
        mode: ClientFormMode,
        context: NSManagedObjectContext = PersistenceController.shared.container
            .viewContext
    ) {
        _vm = StateObject(
            wrappedValue: ClientFormViewModel(
                mode: mode,
                repo: CoreDataClientRepository(context: context)
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Company name *", text: $vm.companyName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("companyNameField")
                } header: {
                    Text("Company")
                } footer: {
                    FieldValidationFooter(
                        count: vm.companyName.count,
                        minLength: ClientFormViewModel.companyNameMin,
                        maxLength: ClientFormViewModel.companyNameMax,
                        isRequired: true
                    )
                }
                Section {
                    TextField("Email *", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("emailField")
                        .textContentType(.emailAddress)
                } header: {
                    Text("Email")
                } footer: {
                    FieldValidationFooter(
                        count: vm.email.count,
                        minLength: ClientFormViewModel.emailMin,
                        maxLength: ClientFormViewModel.emailMax,
                        isRequired: true,
                        formatError: vm.emailFormatError
                    )
                }
                Section {
                    TextField("Phone *", text: $vm.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .accessibilityIdentifier("phoneField")

                } header: {
                    Text("Phone")
                } footer: {
                    FieldValidationFooter(
                        count: vm.phone.count,
                        minLength: ClientFormViewModel.phoneMin,
                        maxLength: ClientFormViewModel.phoneMax,
                        isRequired: true,
                        formatError: vm.phoneFormatError
                    )
                }
            }
            .navigationTitle(vm.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.saveButtonTitle) { attemptSave() }
                        .disabled(!vm.isValid)
                }
            }
            .alert(
                "Couldn't save client",
                isPresented: Binding(
                    get: { saveErrorMessage != nil },
                    set: { if !$0 { saveErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveErrorMessage ?? "")
            }
        }
    }

    private func attemptSave() {
        do {
            try vm.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

#Preview("Create") {
    ClientFormView(
        mode: .create,
        context: PersistenceController.preview.container.viewContext
    )
}

#Preview("Edit") {
    let ctx = PersistenceController.preview.container.viewContext
    let existing = Client.make(
        in: ctx,
        companyName: "Acme Corp",
        email: "hello@acme.com",
        phone: "+1 555 0100"
    )
    return ClientFormView(mode: .edit(existing), context: ctx)
}
