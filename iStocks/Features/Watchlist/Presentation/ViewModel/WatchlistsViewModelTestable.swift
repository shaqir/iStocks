//
//  WatchlistsViewModelTestable.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

#if DEBUG

/// Protocol for testing WatchlistsViewModel
/// Only available in debug builds to keep production code clean
protocol WatchlistsViewModelTestable {
    func removeWatchlist(_ watchlist: Watchlist)
    func updateStockPrices(_ updated: [Stock])
    func replacePrices(_ updatedStocks: [Stock])
}

extension WatchlistsViewModel: WatchlistsViewModelTestable {
    
    func removeWatchlist(_ watchlist: Watchlist) {
        watchlists.removeAll { $0.id == watchlist.id }
        saveAllWatchlists()
    }
    
    func updateStockPrices(_ updated: [Stock]) {
        let priceMap = Dictionary(uniqueKeysWithValues: updated.map { ($0.symbol, $0.price) })
        
        for index in watchlists.indices {
            let watchlist = watchlists[index]
            let updatedStocks = watchlist.stocks.map { stock -> Stock in
                if let newPrice = priceMap[stock.symbol] {
                    return stock.copyWith(price: newPrice)
                }
                return stock
            }
            watchlists[index] = watchlist.copyWith(stocks: updatedStocks)
        }
    }
    
    func replacePrices(_ updatedStocks: [Stock]) {
        let priceMap = Dictionary(uniqueKeysWithValues: updatedStocks.map { ($0.symbol, $0.price) })
        
        watchlists = watchlists.map { oldWatchlist in
            let updatedStocks = oldWatchlist.stocks.map { stock -> Stock in
                guard let newPrice = priceMap[stock.symbol] else { return stock }
                return stock.copyWith(price: newPrice)
            }
            return oldWatchlist.copyWith(stocks: updatedStocks)
        }
        
        AppLogger.debug("Sent price updates to all watchlists", category: .viewModel)
    }
}

#endif
