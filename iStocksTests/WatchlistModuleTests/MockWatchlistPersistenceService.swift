//
//  MockWatchlistPersistenceService.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
@testable import iStocks
import SwiftData

final class MockWatchlistPersistenceService: WatchlistPersistenceProtocol {
    
    var savedStocks: [Stock] = []
    
    var storage: [Watchlist] = [
        Watchlist(id: UUID(), name: "Tech", stocks: MockStockData.allStocks.prefix(1).map { $0}),
        Watchlist(id: UUID(), name: "Energy", stocks: MockStockData.allStocks.suffix(1).map { $0})
    ]
    
    func loadWatchlists() -> [Watchlist] {
        return storage
    }
    
    func saveWatchlists(_ watchlists: [Watchlist]) {
        storage = watchlists
    }
    
    func saveWatchlist(_ watchlist: Watchlist) {
        storage.append(watchlist)
    }
    
    func deleteWatchlist(_ watchlist: Watchlist) {
        storage.removeAll { $0.id == watchlist.id }
    }
    
    func clearWatchlists() {
        storage.removeAll()
    }
    
    // MARK: - All Stocks Methods (REST Repo Support)
    func loadAllStocks() -> [Stock] {
        return savedStocks
    }
    
    func saveAllStocks(_ stocks: [Stock]) {
        savedStocks = stocks
    }
    
    func clearAllStocks() {
        savedStocks.removeAll()
    }
}
