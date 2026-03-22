//
//  EmptyWatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-18.
//

import SwiftUI

struct EmptyWatchlistView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "eye.slash")
                .resizable()
                .frame(width: 60, height: 40)
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            Text("No stocks in this watchlist")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No stocks in this watchlist")
        .accessibilityIdentifier(AccessibilityID.General.emptyState)
    }
}
