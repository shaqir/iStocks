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

    /// Tracks the in-flight refresh task for deduplication.
    /// When a new refresh is requested, any existing in-flight task is cancelled
    /// before starting a new one — prevents redundant network calls.
    private var inFlightRefresh: Task<Void, Never>?

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

    // MARK: - Reentrancy Patterns

    /// Demonstrates the deduct-before-await pattern with rollback on failure.
    ///
    /// Why this matters: Between the optimistic mutation and the await point,
    /// another task could read the actor's state and see the uncommitted holding.
    /// If the network call fails, we rollback — callers who read the interim state
    /// will see the corrected state on their next access.
    func executeTrade(symbol: String, quantity: Double, price: Double, using service: TradeExecutionService) async throws {
        // 1. Snapshot for rollback
        let previousHoldings = holdings

        // 2. Optimistic mutation BEFORE await — actor reentrancy means
        //    other callers see this immediately
        let newHolding = Holding.mock(symbol: symbol, name: symbol, quantity: quantity, averageCost: price, currentPrice: price)
        holdings.append(newHolding)
        lastUpdated = Date()

        // 3. Await network confirmation — actor is free to process other messages here
        do {
            try await service.confirmTrade(symbol: symbol, quantity: quantity, price: price)
            // Trade confirmed — optimistic state is now authoritative
        } catch {
            // 4. Rollback on failure
            holdings = previousHoldings
            lastUpdated = Date()
            throw error
        }
    }

    /// Demonstrates in-flight task deduplication — prevents redundant network calls
    /// when refresh is triggered multiple times rapidly (e.g., pull-to-refresh spam).
    func refreshPrices(using service: PriceRefreshService) {
        // Cancel any existing in-flight refresh
        inFlightRefresh?.cancel()

        let symbols = holdings.map(\.symbol)
        inFlightRefresh = Task {
            guard !Task.isCancelled else { return }
            guard let prices = try? await service.fetchLatestPrices(for: symbols),
                  !Task.isCancelled else { return }

            for (symbol, price) in prices {
                if let idx = self.holdings.firstIndex(where: { $0.symbol == symbol }) {
                    self.holdings[idx] = self.holdings[idx].withUpdatedPrice(price)
                }
            }
            self.lastUpdated = Date()
        }
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
    /// know WHEN to use nonisolated.
    nonisolated func isMarketOpen() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        // NYSE hours: Mon-Fri, 9:30 AM - 4:00 PM ET (simplified to 9-16)
        return (2...6).contains(weekday) && (9...16).contains(hour)
    }
}
