//
//  AddressListView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct AddressListView: View {
    @ObservedObject var client: Client
    @StateObject private var vm: AddressListViewModel
    @FetchRequest private var addresses: FetchedResults<Address>
    
    private let context: NSManagedObjectContext
    
    init(
        client: Client,
        context: NSManagedObjectContext = PersistenceController.shared.container
            .viewContext
    ) {
        _client = ObservedObject(wrappedValue: client)
        self.context = context
        _vm = StateObject(
            wrappedValue: AddressListViewModel(
                repo: CoreDataAddressRepository(context: context)
            )
        )
        _addresses = FetchRequest<Address>(
            sortDescriptors: [SortDescriptor(\.createdAt, order: .forward)],
            predicate: NSPredicate(format: "client == %@", client),
            animation: .default
        )
    }
    
    var body: some View {
        Group {
            if addresses.isEmpty {
                EmptyStateView(
                    title: "No addresses yet",
                    message: "Tap + to add the first address for this client.",
                    systemImage: "mappin.slash"
                )
            } else {
                List {
                    ForEach(addresses) { address in
                        AddressRowView(address: address)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.delete(address)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                Button {
                                    vm.startEdit(address)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                vm.startEdit(address)
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(client.companyName ?? "Addresses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.startCreate()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add address")
            }
        }
        .sheet(item: $vm.formMode) { mode in
            AddressFormView(mode: mode, client: client, context: context)
        }
    }
}

#Preview {
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
    
    return NavigationStack {
        AddressListView(client: firstClient, context: ctx)
    }
    .environment(\.managedObjectContext, ctx)
}
