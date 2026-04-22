
import CoreData
import SwiftUI
struct AddressFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: AddressFormViewModel
    @State private var saveErrorMessage: String?
    init(
        mode: AddressFormMode,
        client: Client,
        context: NSManagedObjectContext = PersistenceController.shared.container.viewContext
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
                Section("Street") {
                    TextField(
                        "Street address",
                        text: $vm.street,
                        axis: .vertical
                    )
                    .lineLimit(1...3)
                    .textInputAutocapitalization(.words)
                    .textContentType(.fullStreetAddress)
                }
                Section("Location") {
                    TextField("City", text: $vm.city)
                        .textInputAutocapitalization(.words)
                        .textContentType(.addressCity)
                    TextField("Country", text: $vm.country)
                        .textInputAutocapitalization(.words)
                        .textContentType(.countryName)
                }
                Section {
                    TextField("Postal code", text: $vm.postalCode)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textContentType(.postalCode)
                } header: {
                    Text("Postal Code")
                } footer: {
                    Text("\(vm.postalCode.count)/\(AddressFormViewModel.maxPostalCodeLength)")
                        .monospacedDigit()
                        .foregroundStyle(
                            vm.postalCode.count >= AddressFormViewModel.maxPostalCodeLength
                                ? .orange
                                : .secondary
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
                    Button(vm.saveButtonTitle) {
                        attemptSave()
                    }
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
    let firstClient = (try? ctx.fetch(request))?.first
        ?? Client.make(in: ctx, companyName: "Preview Client", email: "", phone: "")
    return AddressFormView(mode: .create, client: firstClient, context: ctx)
}
#Preview("Edit") {
    let ctx = PersistenceController.preview.container.viewContext
    let client = Client.make(in: ctx, companyName: "Acme Corp", email: "", phone: "")
    let address = Address.make(
        in: ctx,
        client: client,
        street: "123 Main St",
        city: "New York",
        country: "USA",
        postalCode: "10001"
    )
    return AddressFormView(mode: .edit(address), client: client, context: ctx)
}
