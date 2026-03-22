//
//  BatchProgressView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-20.
//
import SwiftUI

struct BatchProgressView: View {
    let current: Int
    let total: Int
    let retryCount: Int
    let success: Bool
    let isComplete: Bool

    var body: some View {
        if isComplete { EmptyView() }
        else {
            VStack(spacing: 6) {
                ProgressView(value: Double(current), total: Double(total))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                    .accessibilityLabel("Fetching progress")
                    .accessibilityValue("Batch \(current) of \(total)")
                    .accessibilityIdentifier(AccessibilityID.Watchlist.progressBar)

                Text("Fetching batch \(current) of \(total)...")
                    .font(.subheadline)
                    .foregroundColor(success ? .green : .blue)
                    .accessibilityHidden(true)

                if retryCount > 0 {
                    Text("Retrying batch... (\(retryCount) retries)")
                        .font(.caption2)
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.horizontal)
            .transition(.opacity)
            .onChange(of: current) { _, newValue in
                AccessibilityNotification.Announcement("Fetching batch \(newValue) of \(total)").post()
            }
            .onChange(of: retryCount) { _, newValue in
                if newValue > 0 {
                    AccessibilityNotification.Announcement("Retrying batch, attempt \(newValue)").post()
                }
            }
        }
    }
}
