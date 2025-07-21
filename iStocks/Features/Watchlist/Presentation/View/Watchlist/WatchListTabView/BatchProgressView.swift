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

                Text("Fetching batch \(current) of \(total)...")
                    .font(.subheadline)
                    .foregroundColor(success ? .green : .blue)

                if retryCount > 0 {
                    Text("Retrying batch... (\(retryCount) retries)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.horizontal)
            .transition(.opacity)
        }
    }
}
