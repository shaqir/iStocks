//
//  TradeExecutionService.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Protocol for trade execution — used by PortfolioActor for the
/// deduct-before-await pattern demonstration.
nonisolated protocol TradeExecutionService: Sendable {
    func confirmTrade(symbol: String, quantity: Double, price: Double) async throws
}

/// Protocol for batch price refresh — used by PortfolioActor for
/// in-flight task deduplication demonstration.
nonisolated protocol PriceRefreshService: Sendable {
    func fetchLatestPrices(for symbols: [String]) async throws -> [(String, Double)]
}
