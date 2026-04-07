//
//  Holding.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Domain model representing a portfolio holding with cost basis and P&L calculations.
///
/// NOTE (Swift 6.2): Explicitly nonisolated because domain entities must be usable from
/// any isolation context — actors, TaskGroups, @concurrent functions.
/// With defaultIsolation(MainActor.self), this struct would otherwise be implicitly
/// MainActor-isolated, preventing use in background computation.
///
/// Sendable conformance is required for passing across actor boundaries
/// (e.g., PortfolioActor). Since this is a value type with all Sendable properties,
/// the compiler infers conformance automatically — but we declare it explicitly
/// for documentation and Swift 6 strict concurrency readiness.
nonisolated struct Holding: Identifiable, Codable, Equatable, Sendable {

    let id: UUID
    let symbol: String
    let name: String
    let quantity: Double
    let averageCost: Double
    var currentPrice: Double

    // MARK: - Computed Properties

    /// Current market value of this holding
    var marketValue: Double {
        quantity * currentPrice
    }

    /// Total cost basis
    var costBasis: Double {
        quantity * averageCost
    }

    /// Absolute return in currency
    var totalReturn: Double {
        marketValue - costBasis
    }

    /// Return as a percentage of cost basis
    var totalReturnPercentage: Double {
        guard costBasis != 0 else { return 0 }
        return (totalReturn / costBasis) * 100
    }

    /// Whether the holding is profitable
    var isPositive: Bool {
        totalReturn >= 0
    }

    // MARK: - Methods

    /// Returns a new Holding with the price updated — immutable update pattern.
    /// NOTE: We return a new value rather than mutating because Holding may be
    /// shared across actor boundaries where mutation isn't safe.
    func withUpdatedPrice(_ price: Double) -> Holding {
        var copy = self
        copy.currentPrice = price
        return copy
    }

    // MARK: - Mock

    static func mock(
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        quantity: Double = 10,
        averageCost: Double = 145.0,
        currentPrice: Double = 150.0
    ) -> Holding {
        Holding(
            id: UUID(),
            symbol: symbol,
            name: name,
            quantity: quantity,
            averageCost: averageCost,
            currentPrice: currentPrice
        )
    }
}
