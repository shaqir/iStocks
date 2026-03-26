//
//  Dashboard.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Aggregate model representing the portfolio dashboard state.
/// Combines holdings, news, and summary metrics into a single view-ready model.
struct Dashboard: Sendable {

    let holdings: [Holding]
    let news: [News]
    let totalValue: Double
    let lastUpdated: Date

    /// Total return across all holdings
    var totalReturn: Double {
        holdings.reduce(0) { $0 + $1.totalReturn }
    }

    /// Total cost basis across all holdings
    var totalCostBasis: Double {
        holdings.reduce(0) { $0 + $1.costBasis }
    }

    /// Overall portfolio return percentage
    var totalReturnPercentage: Double {
        guard totalCostBasis != 0 else { return 0 }
        return (totalReturn / totalCostBasis) * 100
    }

    // MARK: - Mock

    static func mock() -> Dashboard {
        Dashboard(
            holdings: [
                .mock(symbol: "AAPL", name: "Apple Inc.", currentPrice: 150.0),
                .mock(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: 2800.0),
                .mock(symbol: "MSFT", name: "Microsoft Corp.", currentPrice: 380.0)
            ],
            news: [.mock()],
            totalValue: 33_300.0,
            lastUpdated: Date()
        )
    }
}
