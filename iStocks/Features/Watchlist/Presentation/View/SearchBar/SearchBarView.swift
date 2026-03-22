//
//  SearchBarView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var countText: String
    var onFilterTapped: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            TextField("Search & add", text: $searchText)
                .font(.system(size: 14))
                .disableAutocorrection(true)
                .accessibilityLabel("Search and add stocks")
                .accessibilityIdentifier(AccessibilityID.Watchlist.searchField)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                }
                .accessibilityLabel("Clear search text")
            }

            Spacer()

            Text(countText)
                .foregroundColor(.gray)
                .font(.system(size: 12))
                .accessibilityLabel(countText)

            Button(action: onFilterTapped) {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .foregroundColor(.gray)
            }
            .accessibilityLabel("Filter stocks")
            .accessibilityHint("Opens filter options")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}
