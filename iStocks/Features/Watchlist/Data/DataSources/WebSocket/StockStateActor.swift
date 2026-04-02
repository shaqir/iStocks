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

    /// Returns a snapshot of all current stocks without mutation.
    func snapshot() -> [Stock] {
        Array(currentStocks.values)
    }

    /// Clears all tracked stocks.
    func reset() {
        currentStocks.removeAll()
    }
}
