//
//  AddressFormView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct AddressFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddressFormViewModel
    @State private var saveErrorMessage: String?
   
    init(
        mode: AddressFormMode,
        client: Client,
        context: NSManagedObjectContext = PersistenceController.shared.container
            .viewContext
    ) {
        _vm = StateObject(
            wrappedValue: AddressFormViewModel(
                mode: mode,
                client: client,
                repo: CoreDataAddressRepository(context: context)
            )
        )
    }
   
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "Street address *",
                        text: $vm.street,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.words)
                    .textContentType(.fullStreetAddress)
                    .accessibilityIdentifier("streetField")
                } header: {
                    Text("Street")
                } footer: {
                    FieldValidationFooter(
                        count: vm.street.count,
                        minLength: AddressFormViewModel.streetMin,
                        maxLength: AddressFormViewModel.streetMax,
                        isRequired: true
                    )
                }
                Section {
                    TextField("City *", text: $vm.city)
                        .textInputAutocapitalization(.words)
                        .textContentType(.addressCity)
                        .accessibilityIdentifier("cityField")
                } header: {
                    Text("City")
                } footer: {
                    FieldValidationFooter(
                        count: vm.city.count,
                        minLength: AddressFormViewModel.cityMin,
                        maxLength: AddressFormViewModel.cityMax,
                        isRequired: true
                    )
                }
                Section {
                    TextField(
                        "Country *",
                        text: Binding(
                            get: { vm.country },
                            set: { vm.country = String($0.prefix(AddressFormViewModel.countryMax)) }
                        )
                    )
                        .textInputAutocapitalization(.words)
                        .textContentType(.countryName)
                        .accessibilityIdentifier("countryField")
                } header: {
                    Text("Country")
                } footer: {
                    FieldValidationFooter(
                        count: vm.country.count,
                        minLength: AddressFormViewModel.countryMin,
                        maxLength: AddressFormViewModel.countryMax,
                        isRequired: true
                    )
                }
                Section {
                    TextField("Postal code *", text: $vm.postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textContentType(.postalCode)
                        .accessibilityIdentifier("postalCodeField")

                } header: {
                    Text("Postal Code")
                } footer: {
                    FieldValidationFooter(
                        count: vm.postalCode.count,
                        minLength: AddressFormViewModel.postalCodeMin,
                        maxLength: AddressFormViewModel.postalCodeMax,
                        isRequired: true
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
                "Couldn't save address",
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
    let ctx = PersistenceController.preview.container.viewContext
    let request: NSFetchRequest<Client> = Client.fetchRequest()
    let firstClient =
        (try? ctx.fetch(request))?.first
        ?? Client.make(
            in: ctx,
            companyName: "Preview Client",
            email: "",
            phone: ""
        )
    return AddressFormView(mode: .create, client: firstClient, context: ctx)
}
#Preview("Edit") {
    let ctx = PersistenceController.preview.container.viewContext
    let client = Client.make(
        in: ctx,
        companyName: "Acme Corp",
        email: "",
        phone: ""
    )
    let address = Address.make(
        in: ctx,
        client: client,
        street: "123 Main St",
        city: "New York",
        country: "United States",
        postalCode: "10001"
    )
    return AddressFormView(mode: .edit(address), client: client, context: ctx)
}
