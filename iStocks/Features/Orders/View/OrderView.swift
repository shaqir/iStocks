//
//  OrderView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-28.
//

import SwiftUI

struct OrderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Orders")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Orders")
            .accessibilityLabel("Orders")
            .accessibilityAddTraits(.isHeader)
        }
    }
}
