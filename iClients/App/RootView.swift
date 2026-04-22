//
//  RootView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import CoreData
import SwiftUI

struct RootView: View {
    @State private var didFinishSplash = false
    var body: some View {
        if didFinishSplash {
            NavigationStack {
                ClientListView()
            }
        } else {
            SplashView {
                withAnimation(.easeInOut(duration: 0.3)) {
                    didFinishSplash = true
                }
            }
        }
    }
}
#Preview {
    RootView()
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
}
