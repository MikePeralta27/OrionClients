//
//  SplashView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//

import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.crop.square.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, options: .speed(0.4))
            Text("iClients")
                .font(.largeTitle.weight(.semibold))
            Text("Address Management")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            try? await Task.sleep(for: .seconds(2.5))
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
