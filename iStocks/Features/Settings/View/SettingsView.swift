//
//  SettingsView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Settings")
            .accessibilityLabel("Settings")
            .accessibilityAddTraits(.isHeader)
        }
    }
}
