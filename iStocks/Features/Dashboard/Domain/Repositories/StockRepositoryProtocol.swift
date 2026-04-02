//
//  StockRepositoryProtocol.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Repository protocol for stock and portfolio data operations.
///
/// NOTE: This protocol lives in the Domain layer with zero UIKit/SwiftUI imports.
/// The Data layer provides the concrete implementation (StockRepository) that
/// uses APIClient for remote data and PortfolioCache for offline support.
/// Sendable conformance is required because this protocol is used across
/// actor boundaries (PortfolioActor calls through use cases that hold this).
protocol StockRepositoryProtocol: Sendable {

    /// Fetches the user's portfolio holdings from remote or cache.
    func fetchHoldings(userId: String) async throws -> [Holding]

    /// Fetches the current price for a single symbol.
    func fetchPrice(for symbol: String) async throws -> Double

    /// Fetches news articles related to the given symbols.
    func fetchNews(for symbols: [String]) async throws -> [News]
}
