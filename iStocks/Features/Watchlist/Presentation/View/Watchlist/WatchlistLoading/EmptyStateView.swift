//
//  EmptyStateView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-12.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String?
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            if let icon = icon {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .accessibilityHint("Double tap to try again")
                    .accessibilityIdentifier(AccessibilityID.General.retryButton)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.General.emptyState)
    }
}
