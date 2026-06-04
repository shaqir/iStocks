//
//  WatchlistRow.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import SwiftUI

struct WatchlistRow: View {
    let stock: Stock
    let isAnimated: Bool

    @State private var didTriggerHaptic = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Row: Name | Change %
            HStack {
                Text(stock.name)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%@%.2f%%", stock.priceChangePercentage >= 0 ? "+" : "", stock.priceChangePercentage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stock.isPriceUp ? .green : .red)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }

            // Middle Row: Symbol | Price
            HStack {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(stock.price.currencyFormatted)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stock.isPriceUp ? .green : .red)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }

            // Bottom Row: Exchange | Prev Close
            HStack {
                Text(stock.exchange)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Spacer()

                Text("Prev \(stock.previousPrice.currencyFormatted)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stockAccessibilityLabel)
        .accessibilityValue("Price \(stock.price.currencyFormatted)")
        .accessibilityHint("Opens detailed view of this stock")
        .accessibilityIdentifier(AccessibilityID.Watchlist.stockRow)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAnimated ? flashColor() : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.8), value: isAnimated)
        )
        .onChange(of: isAnimated) { _, newValue in
            if newValue && !didTriggerHaptic {
                triggerHaptic()
                didTriggerHaptic = true
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    didTriggerHaptic = false
                }
            }
        }
    }

    private func flashColor() -> Color {
        if stock.isPriceUp {
            return Color.green.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Accessibility

    private var stockAccessibilityLabel: String {
        let direction = stock.isPriceUp ? "up" : "down"
        let changePct = String(format: "%.2f", abs(stock.priceChangePercentage))
        return "\(stock.name), \(stock.symbol), price \(direction) \(changePct) percent, \(stock.exchange)"
    }
}
