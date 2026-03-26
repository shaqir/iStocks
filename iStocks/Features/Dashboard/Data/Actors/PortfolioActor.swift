//
//  PortfolioActor.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Thread-safe portfolio state management using Swift actors.
///
/// NOTE: Actor isolation ensures only one task accesses holdings at a time —
/// no data races, no locks, no serial DispatchQueues. The compiler enforces
/// that all access goes through `await`, catching concurrency bugs at build time.
///
/// This replaces the old pattern of:
///   private let queue = DispatchQueue(label: "com.app.portfolio")
///   queue.sync { holdings.append(holding) }
///
/// With actors, the equivalent is simply:
///   await portfolio.addHolding(holding)
actor PortfolioActor {

    private(set) var holdings: [Holding] = []
    private(set) var lastUpdated: Date?

    // MARK: - Mutations

    func update(_ newHoldings: [Holding]) {
        holdings = newHoldings
        lastUpdated = Date()
    }

    func addHolding(_ holding: Holding) {
        holdings.append(holding)
        lastUpdated = Date()
    }

    func removeHolding(symbol: String) {
        holdings.removeAll { $0.symbol == symbol }
        lastUpdated = Date()
    }

    // MARK: - Queries

    func totalValue() -> Double {
        holdings.reduce(0) { $0 + $1.marketValue }
    }

    func holding(for symbol: String) -> Holding? {
        holdings.first { $0.symbol == symbol }
    }

    // MARK: - Nonisolated

    /// NOTE: nonisolated because this method doesn't access any mutable actor state.
    /// Callers don't need `await` — it's a pure computation based on current time.
    /// This is a key interview talking point: know WHEN to use nonisolated.
    nonisolated func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        // NYSE hours: Mon-Fri, 9:30 AM - 4:00 PM ET (simplified to 9-16)
        return (2...6).contains(weekday) && (9...16).contains(hour)
    }
}
