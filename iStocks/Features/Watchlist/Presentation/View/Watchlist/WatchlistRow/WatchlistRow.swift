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

    // Optional: Trigger haptic once per change
    @State private var didTriggerHaptic = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top Row: Qty • Avg | P&L %
            HStack {
                Text("Qty: \(Int(stock.qty)) • Avg: \(String(format: "%.2f", stock.averageBuyPrice))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Spacer()

                Text(String(format: "%.2f%%", stock.pnlPercentage))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stock.pnl >= 0 ? .green : .red)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }

            // Middle Row: Symbol | ₹ P&L
            HStack {
                Text(stock.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                Text(stock.pnl.currencyFormatted)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(stock.pnl >= 0 ? .green : .red)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }

            // Bottom Row: Invested | LTP
            HStack {
                Text("Invested \(stock.invested.currencyFormatted)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Spacer()

                Text("LTP \(stock.price.currencyFormatted)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .scaleEffect(isAnimated ? 1.05 : 1.0)
                    .animation(.easeOut(duration: 0.4), value: isAnimated)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAnimated ? flashColor() : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.8), value: isAnimated)
        )
        .onChange(of: isAnimated) {_, newValue in
            if newValue && !didTriggerHaptic {
                triggerHaptic()
                didTriggerHaptic = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    didTriggerHaptic = false
                }
            }
        }
    }

    private func flashColor() -> Color {
        if stock.pnl > 0 {
            return Color.green.opacity(colorScheme == .dark ? 0.1 : 0.1)
        } else if stock.pnl < 0 {
            return Color.red.opacity(colorScheme == .dark ? 0.1 : 0.1)
        } else {
            return Color.yellow.opacity(0.1)
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
