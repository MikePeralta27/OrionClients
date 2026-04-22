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
                    TextField("Company name", text: $vm.companyName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Company")
                } footer: {
                    Text(
                        "\(vm.companyName.count)/\(ClientFormViewModel.maxCompanyNameLength)"
                    )
                    .monospacedDigit()
                    .foregroundStyle(
                        vm.companyName.count
                            >= ClientFormViewModel.maxCompanyNameLength
                            ? .orange
                            : .secondary
                    )
                }
                Section("Contact") {
                    TextField("Email", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.emailAddress)
                    TextField("Phone", text: $vm.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle(vm.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.saveButtonTitle) {
                        attemptSave()
                    }
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
