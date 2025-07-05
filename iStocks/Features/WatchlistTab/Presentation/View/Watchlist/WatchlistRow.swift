//
//  WatchlistRow.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import SwiftUI

import SwiftUI

struct WatchlistRow: View {
    let stock: Stock

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
            }

        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    WatchlistRow(stock: MockStockData.allStocks.first!)
}
