//
//  ClientListView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct ClientListView: View {
    @StateObject private var vm: ClientListViewModel
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)]
    ) private var clients: FetchedResults<Client>
    
    private let context: NSManagedObjectContext
    
    init(
        context: NSManagedObjectContext = PersistenceController.shared.container
            .viewContext
    ) {
        self.context = context
        _vm = StateObject(
            wrappedValue: ClientListViewModel(
                repo: CoreDataClientRepository(context: context)
            )
        )
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 170), spacing: 16)
    ]
    
    var body: some View {
        Group {
            if clients.isEmpty {
                EmptyStateView(
                    title: "No clients yet",
                    message: "Tap + to add your first client.",
                    systemImage: "person.2.slash"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(clients) { client in
                            NavigationLink(value: client) {
                                ClientCardView(client: client)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    vm.startEdit(client)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    vm.delete(client)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("iClients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm.startCreate()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add client")
            }
        }
        .sheet(item: $vm.formMode) { mode in
            ClientFormView(mode: mode, context: context)
        }
        .navigationDestination(for: Client.self) { client in
            AddressListView(client: client, context: context)
        }
    }
}

#Preview {
    let previewContext = PersistenceController.preview.container.viewContext
    return NavigationStack {
        ClientListView(context: previewContext)
    }
    .environment(\.managedObjectContext, previewContext)
}
