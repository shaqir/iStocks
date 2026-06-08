//
//  StockStateActor.swift
//  iStocks
//
//  Created by Sakir Saiyed
//
//  Replaces serial DispatchQueue with compiler-enforced actor isolation
//  for thread-safe access to shared stock price state.

import Foundation

/// Actor that protects shared mutable stock state from data races.
///
/// Previously, `WebSocketStockRepositoryImpl` used a serial `DispatchQueue`
/// to synchronize access to `currentStocks`. This actor achieves the same
/// thread safety with compile-time guarantees — the Swift compiler prevents
/// unsynchronized access, eliminating an entire class of runtime bugs.
actor StockStateActor {

    private var currentStocks: [String: Stock] = [:]

    /// Updates a stock by symbol and returns the full current snapshot.
    /// - Returns: All current stocks after the update.
    func update(symbol: String, stock: Stock) -> [Stock] {
        currentStocks[symbol] = stock
        return Array(currentStocks.values)
    }

    /// Atomically reads the previous price for `symbol`, builds the updated stock from it,
    /// and stores the result — all within a single actor hop.
    ///
    /// This replaces the previous two-step `snapshot()` then `update()` pattern at the call
    /// site, which had a stale-read window: between the two awaits another trade for the same
    /// symbol could land, so the price-direction (`isPriceUp`) could be computed against an
    /// out-of-date previous price. Collapsing both into one actor method makes it atomic.
    ///
    /// - Returns: the full snapshot after the update, or `nil` if `buildStock` returned `nil`.
    func apply(symbol: String, buildStock: @Sendable (_ previousPrice: Double) -> Stock?) -> [Stock]? {
        let previousPrice = currentStocks[symbol]?.price ?? 0
        guard let stock = buildStock(previousPrice) else { return nil }
        currentStocks[symbol] = stock
        return Array(currentStocks.values)
    }

    /// Returns a snapshot of all current stocks without mutation.
    func snapshot() -> [Stock] {
        Array(currentStocks.values)
    }

    /// Clears all tracked stocks.
    func reset() {
        currentStocks.removeAll()
    }
}
