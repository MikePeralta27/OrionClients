//
//  CountryPickerView.swift
//  iClients
//
//  Created by Michael Peralta on 4/22/26.
//


import SwiftUI
struct CountryPickerView: View {
    @Binding var selectedCountry: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    private static let allCountries: [String] = {
        let locale = Locale.current
        return Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 }
            .compactMap { locale.localizedString(forRegionCode: $0) }
            .sorted()
    }()
    private var filtered: [String] {
        guard !searchText.isEmpty else { return Self.allCountries }
        return Self.allCountries.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }
    var body: some View {
        List(filtered, id: \.self) { country in
            Button {
                selectedCountry = country
                dismiss()
            } label: {
                HStack {
                    Text(country)
                        .foregroundStyle(.primary)
                    Spacer()
                    if country == selectedCountry {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search countries")
        .navigationTitle("Country")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    NavigationStack {
        CountryPickerView(selectedCountry: .constant("United States"))
    }
}
