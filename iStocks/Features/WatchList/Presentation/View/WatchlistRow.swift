//
//  WatchlistRow.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import SwiftUI

struct WatchlistRow: View {
    let stock: Stock

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stock.symbol)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f", stock.ltp))
                    .bold()
            }

            HStack {
                let isUp = stock.pnl >= 0
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(isUp ? .green : .red)

                Text("P&L: \(String(format: "%.2f", stock.pnl))")
                    .foregroundColor(isUp ? .green : .red)

                Spacer()

                Text(String(format: "%.2f%%", stock.pnlPercentage))
                    .foregroundColor(isUp ? .green : .red)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    WatchlistRow(stock: MockData.sampleStocks.first!)
}
