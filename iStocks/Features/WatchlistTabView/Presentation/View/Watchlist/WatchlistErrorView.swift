//
//  ErrorView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-01.
//

import SwiftUI

struct WatchlistErrorView: View {
    let error: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                    .shadow(radius: 8)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 10) {
                Text("Oops! Something went wrong")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Button(action: retryAction) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [Color.indigo, Color.cyan]),
                        startPoint: .leading,
                        endPoint: .trailing))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)
        )
        .padding()
        .transition(.scale)
        .animation(.easeInOut, value: error)
    }

    private var errorMessage: String {
        if let localizedError = error as? LocalizedError {
            return localizedError.errorDescription ?? "Unknown error occurred."
        }
        return error
    }
}
