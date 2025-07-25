//
//  WatchlistFactory.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
@testable import iStocks

///Testing
struct WatchlistFactory {
    static func createMockWatchlists() -> [Watchlist] {
        let names = [
            "Communication", "Consumer", "Consumer Discretionary", "Consumer Staples",
            "Energy", "Financials", "Healthcare", "IT", "Industrials", "Technology"
        ]

        let sampleStocks = Array(MockStockData.allStocks.prefix(3)) // At least 1-3 per watchlist

        return names.map { name in
            Watchlist(id: UUID(), name: name, stocks: sampleStocks)
        }
    }
}
